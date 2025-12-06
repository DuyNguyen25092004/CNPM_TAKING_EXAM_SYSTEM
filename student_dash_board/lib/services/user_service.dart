// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Đồng bộ user từ Authentication sang Firestore
  /// Tự động tạo document nếu chưa tồn tại với role mặc định là STUDENT
  static Future<String?> syncUserAndGetRole(User user) async {
    try {
      print('🔄 Syncing user: ${user.uid}');
      print('📧 Email: ${user.email}');

      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      String role;

      if (doc.exists) {
        // Document đã tồn tại - lấy role và cập nhật lastLogin
        final data = doc.data()!;
        role = data['role'] as String? ?? 'student';

        print('✅ User exists in Firestore with role: $role');

        // Cập nhật thông tin đăng nhập
        await docRef.update({
          'email': user.email ?? '',
          'displayName': _extractDisplayName(user),
          'isActive': true,
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Document chưa tồn tại - tạo mới với role mặc định là STUDENT
        print('🆕 Creating new user document in Firestore');
        print('   UID: ${user.uid}');
        print('   Email: ${user.email}');

        // Xác định role - ưu tiên teacher nếu có trong email, còn lại là student
        role = _determineDefaultRole(user.email);

        // Trích xuất studentId từ email (9 chữ số đầu)
        final studentId = _extractStudentId(user.email);

        try {
          final userData = {
            'createdAt': FieldValue.serverTimestamp(),
            'displayName': _extractDisplayName(user),
            'email': user.email ?? '',
            'isActive': true,
            'lastLogin': FieldValue.serverTimestamp(),
            'role': role,
            'studentId': studentId, // Thêm studentId cho student
          };

          print('   Creating document with data: $userData');

          await docRef.set(userData);

          print('✅ User document created successfully!');
          print('   Role: $role');
          if (studentId.isNotEmpty) {
            print('   Student ID: $studentId');
          }

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
      await prefs.setString('user_id', user.uid);
      await prefs.setString('user_email', user.email ?? '');

      print('💾 Role cached locally');

      return role;
    } catch (e) {
      print('❌ Error syncing user: $e');

      // Thử lấy từ cache nếu có lỗi
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedRole = prefs.getString('user_role');
        final cachedUserId = prefs.getString('user_id');

        if (cachedRole != null && cachedUserId == user.uid) {
          print('⚠️ Using cached role due to error: $cachedRole');
          return cachedRole;
        }
      } catch (_) {}

      return null;
    }
  }

  /// Trích xuất 9 chữ số đầu từ email làm studentId
  static String _extractStudentId(String? email) {
    if (email == null) return '';

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
  /// MẶC ĐỊNH: student
  /// CHỈ LÀ teacher nếu email chứa các từ khóa đặc biệt
  static String _determineDefaultRole(String? email) {
    if (email == null) return 'student';

    final emailLower = email.toLowerCase();

    // ONLY những email này mới là teacher
    // Tất cả các email khác đều là student
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

    // Mặc định tất cả là student
    print('👨‍🎓 Default role assigned: student');
    return 'student';
  }

  /// Lấy role từ Firestore (không tự động tạo)
  static Future<String?> getUserRole(String userId) async {
    try {
      print('🔍 Getting role for user: $userId');

      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final role = doc.data()?['role'] as String?;
        print('✅ Role found: $role');

        // Cache
        if (role != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', role);
          await prefs.setString('user_id', userId);
        }

        return role;
      }

      print('⚠️ User document not found');

      // Thử lấy từ cache
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString('user_role');
      final cachedUserId = prefs.getString('user_id');

      if (cachedRole != null && cachedUserId == userId) {
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

        if (cachedRole != null && cachedUserId == userId) {
          print('📦 Returning cached role despite error: $cachedRole');
          return cachedRole;
        }
      } catch (_) {}

      return null;
    }
  }

  /// Set role cho user (cho admin)
  static Future<void> setUserRole(String userId, String role) async {
    try {
      print('🔧 Setting role for user: $userId to $role');

      await _firestore.collection('users').doc(userId).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật cache
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('user_id') == userId) {
        await prefs.setString('user_role', role);
      }

      print('✅ Role updated successfully');
    } catch (e) {
      print('❌ Error setting role: $e');
      rethrow;
    }
  }

  /// Lấy thông tin user đầy đủ
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Cập nhật profile user
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User profile updated');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  /// Đánh dấu user inactive khi đăng xuất
  static Future<void> markUserInactive(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
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
      final userId = prefs.getString('user_id');

      // Đánh dấu inactive trong Firestore
      if (userId != null) {
        await markUserInactive(userId);
      }

      // Xóa cache
      await prefs.remove('user_role');
      await prefs.remove('user_id');
      await prefs.remove('user_email');

      print('✅ User cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Kiểm tra user có tồn tại trong Firestore không
  static Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking user existence: $e');
      return false;
    }
  }

  /// Lấy studentId từ user document
  static Future<String?> getStudentId(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['studentId'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ Error getting studentId: $e');
      return null;
    }
  }

  /// Tạo hoặc cập nhật user document (dùng cho admin)
  static Future<void> createOrUpdateUser({
    required String userId,
    required String email,
    required String role,
    String? displayName,
  }) async {
    try {
      final studentId = _extractStudentId(email);

      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'role': role,
        'displayName': displayName ?? _extractDisplayName(
          FirebaseAuth.instance.currentUser ?? User as User,
        ),
        'studentId': studentId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ User created/updated successfully');
      print('   Role: $role');
      print('   Student ID: $studentId');
    } catch (e) {
      print('❌ Error creating/updating user: $e');
      rethrow;
    }
  }
}