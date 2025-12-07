// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Trích xuất 9 chữ số đầu từ email làm studentId/userId
  static String extractStudentId(String? email) {
    if (email == null || email.isEmpty) return '';

    final parts = email.split('@');
    if (parts.isEmpty) return '';

    // Lấy phần trước @
    final username = parts[0];

    // Trích xuất 9 chữ số đầu tiên
    final digits = username.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length >= 9) {
      return digits.substring(0, 9);
    }

    return digits;
  }

  /// Đồng bộ user từ Authentication sang Firestore
  /// SỬ DỤNG 9 CHỮ SỐ ĐẦU EMAIL LÀM DOCUMENT ID
  ///
  /// ⚡ LƯU Ý: Hàm này sẽ được gọi tự động bởi AuthSyncService
  /// nhưng vẫn có thể gọi thủ công khi cần
  static Future<String?> syncUserAndGetRole(User user) async {
    try {
      print('🔄 [UserService] Syncing user: ${user.uid}');
      print('📧 Email: ${user.email}');

      // Trích xuất studentId từ email (9 chữ số đầu)
      final studentId = extractStudentId(user.email);

      if (studentId.isEmpty) {
        print('❌ Cannot extract student ID from email: ${user.email}');
        throw Exception('Email không chứa mã sinh viên hợp lệ (9 chữ số)');
      }

      print('🎓 Extracted Student ID: $studentId');

      // SỬ DỤNG STUDENT ID LÀM DOCUMENT ID thay vì user.uid
      final docRef = _firestore.collection('users').doc(studentId);
      final doc = await docRef.get();

      String role;

      // Chuẩn bị data đồng bộ từ Authentication
      final authData = {
        'authUid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? _extractDisplayName(user),
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'phoneNumber': user.phoneNumber,
        'isActive': true,
        'lastLogin': FieldValue.serverTimestamp(),
        'lastSyncAt': FieldValue.serverTimestamp(),
      };

      if (doc.exists) {
        // Document đã tồn tại - cập nhật data từ Authentication
        final data = doc.data()!;
        role = data['role'] as String? ?? 'student';

        print('✅ User exists in Firestore with role: $role');
        print('🔄 Updating with latest Authentication data...');

        // Cập nhật thông tin từ Authentication + giữ nguyên role và metadata
        await docRef.update({
          ...authData,
          // Không ghi đè các field quan trọng từ Firestore
          'role': role, // Giữ nguyên role từ Firestore
          'studentId': studentId, // Giữ nguyên studentId
        });

        print('✅ Synced from Authentication → Firestore');
      } else {
        // Document chưa tồn tại - tạo mới
        print('🆕 Creating new user document in Firestore');
        print('   Student ID (Document ID): $studentId');
        print('   Auth UID: ${user.uid}');
        print('   Email: ${user.email}');

        // Xác định role mặc định
        role = _determineDefaultRole(user.email);

        try {
          await docRef.set({
            ...authData,
            'studentId': studentId, // Trùng với document ID
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });

          print('✅ User document created successfully!');
          print('   Document ID (Student ID): $studentId');
          print('   Role: $role');
          print('   ✨ Future changes in Authentication will auto-sync');

          // Verify document was created
          final verifyDoc = await docRef.get();
          if (verifyDoc.exists) {
            print('✅ Document verified in Firestore');
          } else {
            print('⚠️ Document not found after creation - possible permissions issue');
          }
        } catch (createError) {
          print('❌ Error creating user document: $createError');
          print('   This might be a Firestore rules issue');
          rethrow;
        }
      }

      // Cache vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      await prefs.setString('user_id', studentId);
      await prefs.setString('auth_uid', user.uid);
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setString('student_id', studentId);

      print('💾 Role and IDs cached locally');
      print('✨ Auto-sync is active: Authentication ↔️ Firestore');

      return role;
    } catch (e) {
      print('❌ Error syncing user: $e');

      // Thử lấy từ cache nếu có lỗi
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedRole = prefs.getString('user_role');
        final cachedEmail = prefs.getString('user_email');

        if (cachedRole != null && cachedEmail == user.email) {
          print('⚠️ Using cached role due to error: $cachedRole');
          return cachedRole;
        }
      } catch (_) {}

      return null;
    }
  }

  /// Trích xuất tên hiển thị từ email hoặc displayName
  static String _extractDisplayName(User user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    if (user.email != null) {
      // Lấy phần trước @ làm tên
      final username = user.email!.split('@')[0];
      // Capitalize chữ cái đầu
      return username.substring(0, 1).toUpperCase() + username.substring(1);
    }

    return 'User';
  }

  /// Xác định role mặc định dựa trên email
  static String _determineDefaultRole(String? email) {
    if (email == null) return 'student';

    final emailLower = email.toLowerCase();

    final teacherKeywords = [
      'teacher',
      'admin',
      'gv',
      'giangvien',
      'giaovien',
      'instructor',
      'professor',
      'giảng_viên',
    ];

    for (var keyword in teacherKeywords) {
      if (emailLower.contains(keyword)) {
        print('👨‍🏫 Detected teacher keyword: $keyword');
        return 'teacher';
      }
    }

    print('👨‍🎓 Default role assigned: student');
    return 'student';
  }

  /// Lấy role từ Firestore bằng studentId
  static Future<String?> getUserRole(String studentId) async {
    try {
      print('🔍 Getting role for student: $studentId');

      final doc = await _firestore.collection('users').doc(studentId).get();

      if (doc.exists) {
        final role = doc.data()?['role'] as String?;
        print('✅ Role found: $role');

        // Cache
        if (role != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', role);
          await prefs.setString('user_id', studentId);
        }

        return role;
      }

      print('⚠️ User document not found');

      // Thử lấy từ cache
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString('user_role');
      final cachedUserId = prefs.getString('user_id');

      if (cachedRole != null && cachedUserId == studentId) {
        print('📦 Using cached role: $cachedRole');
        return cachedRole;
      }

      return null;
    } catch (e) {
      print('❌ Error getting user role: $e');

      // Fallback: cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedRole = prefs.getString('user_role');
        final cachedUserId = prefs.getString('user_id');

        if (cachedRole != null && cachedUserId == studentId) {
          print('📦 Returning cached role despite error: $cachedRole');
          return cachedRole;
        }
      } catch (_) {}

      return null;
    }
  }

  /// Lấy studentId từ Auth User
  static Future<String?> getStudentId(User user) async {
    final studentId = extractStudentId(user.email);
    return studentId.isNotEmpty ? studentId : null;
  }

  /// Lấy studentId từ AuthUID (tìm trong Firestore)
  static Future<String?> getStudentIdFromAuthUid(String authUid) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('authUid', isEqualTo: authUid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id; // Document ID = studentId
      }

      return null;
    } catch (e) {
      print('❌ Error getting studentId from authUid: $e');
      return null;
    }
  }

  /// Set role cho user (cho admin)
  /// ⚠️ Lưu ý: Role chỉ được quản lý trong Firestore, không sync ngược về Authentication
  static Future<void> setUserRole(String studentId, String role) async {
    try {
      print('🔧 Setting role for student: $studentId to $role');

      await _firestore.collection('users').doc(studentId).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật cache
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('user_id') == studentId) {
        await prefs.setString('user_role', role);
      }

      print('✅ Role updated successfully');
      print('ℹ️ Note: Role is managed in Firestore only');
    } catch (e) {
      print('❌ Error setting role: $e');
      rethrow;
    }
  }

  /// Lấy thông tin user đầy đủ
  static Future<Map<String, dynamic>?> getUserProfile(String studentId) async {
    try {
      final doc = await _firestore.collection('users').doc(studentId).get();

      if (doc.exists) {
        final data = doc.data()!;
        print('📋 User profile loaded:');
        print('   Student ID: ${data['studentId']}');
        print('   Email: ${data['email']}');
        print('   Role: ${data['role']}');
        print('   Last Sync: ${data['lastSyncAt']}');
        return data;
      }

      return null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Cập nhật profile user
  /// ⚠️ Chỉ cập nhật các field không phải từ Authentication
  /// Các field như email, displayName sẽ được sync tự động từ Authentication
  static Future<void> updateUserProfile(String studentId, Map<String, dynamic> data) async {
    try {
      // Loại bỏ các field được sync từ Authentication
      final updatableData = Map<String, dynamic>.from(data);
      updatableData.remove('authUid');
      updatableData.remove('email');
      updatableData.remove('displayName');
      updatableData.remove('photoURL');
      updatableData.remove('emailVerified');
      updatableData.remove('phoneNumber');

      print('📝 Updating user profile (non-auth fields only)');

      await _firestore.collection('users').doc(studentId).update({
        ...updatableData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ User profile updated');
      print('ℹ️ Auth-related fields are auto-synced from Authentication');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  /// Đánh dấu user inactive khi đăng xuất
  static Future<void> markUserInactive(String studentId) async {
    try {
      await _firestore.collection('users').doc(studentId).update({
        'isActive': false,
        'lastLogout': FieldValue.serverTimestamp(),
      });
      print('✅ User marked as inactive');
    } catch (e) {
      print('⚠️ Could not mark user inactive: $e');
    }
  }

  /// Xóa cache local khi đăng xuất
  static Future<void> clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getString('user_id');

      // Đánh dấu inactive trong Firestore
      if (studentId != null) {
        await markUserInactive(studentId);
      }

      // Xóa cache
      await prefs.remove('user_role');
      await prefs.remove('user_id');
      await prefs.remove('auth_uid');
      await prefs.remove('user_email');
      await prefs.remove('student_id');

      print('✅ User cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Kiểm tra user có tồn tại trong Firestore không
  static Future<bool> userExists(String studentId) async {
    try {
      final doc = await _firestore.collection('users').doc(studentId).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking user existence: $e');
      return false;
    }
  }

  /// Tạo hoặc cập nhật user document (dùng cho admin)
  static Future<void> createOrUpdateUser({
    required String email,
    required String role,
    String? displayName,
    String? authUid,
  }) async {
    try {
      final studentId = extractStudentId(email);

      if (studentId.isEmpty) {
        throw Exception('Cannot extract student ID from email: $email');
      }

      await _firestore.collection('users').doc(studentId).set({
        'authUid': authUid,
        'studentId': studentId,
        'email': email,
        'role': role,
        'displayName': displayName ?? email.split('@')[0],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ User created/updated successfully');
      print('   Document ID (Student ID): $studentId');
      print('   Role: $role');
    } catch (e) {
      print('❌ Error creating/updating user: $e');
      rethrow;
    }
  }

  /// Lấy sync status của user
  static Future<Map<String, dynamic>> getSyncStatus(String studentId) async {
    try {
      final doc = await _firestore.collection('users').doc(studentId).get();

      if (!doc.exists) {
        return {
          'synced': false,
          'message': 'User document not found',
        };
      }

      final data = doc.data()!;
      final lastSync = data['lastSyncAt'] as Timestamp?;
      final lastLogin = data['lastLogin'] as Timestamp?;

      return {
        'synced': true,
        'lastSyncAt': lastSync?.toDate().toString() ?? 'Never',
        'lastLogin': lastLogin?.toDate().toString() ?? 'Never',
        'email': data['email'],
        'emailVerified': data['emailVerified'] ?? false,
        'role': data['role'],
        'isActive': data['isActive'] ?? false,
      };
    } catch (e) {
      print('❌ Error getting sync status: $e');
      return {
        'synced': false,
        'error': e.toString(),
      };
    }
  }
}

// ============================================
// LƯU Ý VỀ AUTO-SYNC
// ============================================
//
// Với AuthSyncService được kích hoạt trong main.dart:
//
// ✅ TỰ ĐỘNG SYNC (Authentication → Firestore):
// - email
// - displayName
// - photoURL
// - emailVerified
// - phoneNumber
// - authUid
// - lastLogin
// - lastSyncAt
//
// 🔒 CHỈ QUẢN LÝ TRONG FIRESTORE:
// - role (student/teacher)
// - studentId
// - createdAt
// - isActive
// - custom fields khác
//
// ⚠️ KHÔNG SYNC NGƯỢC (Firestore → Authentication):
// - Firestore chỉ là mirror/copy của Authentication
// - Thay đổi trong Firestore không ảnh hưởng đến Authentication
// - Để thay đổi email/displayName, phải dùng Firebase Authentication API
//
// ============================================