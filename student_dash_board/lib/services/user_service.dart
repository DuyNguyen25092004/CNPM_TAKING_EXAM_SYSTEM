// ============= FILE: lib/services/user_service.dart =============
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Đồng bộ user từ Authentication sang Firestore
  /// Tự động tạo document nếu chưa tồn tại
  static Future<String?> syncUserAndGetRole(User user) async {
    try {
      print('🔄 Syncing user: ${user.uid}');

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
          'displayName': user.email?.split('@')[0] ?? user.displayName ?? 'User',
          'isActive': true,
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Document chưa tồn tại - tạo mới với role mặc định
        print('📝 Creating new user document in Firestore');

        // Xác định role mặc định dựa trên email
        role = _determineDefaultRole(user.email);

        await docRef.set({
          'createdAt': FieldValue.serverTimestamp(),
          'displayName': user.email?.split('@')[0] ?? user.displayName ?? 'User',
          'email': user.email ?? '',
          'isActive': true,
          'lastLogin': FieldValue.serverTimestamp(),
          'role': role,
        });

        print('✅ User document created with role: $role');
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

  /// Xác định role mặc định dựa trên email
  static String _determineDefaultRole(String? email) {
    if (email == null) return 'student';

    final emailLower = email.toLowerCase();

    // Kiểm tra các pattern để xác định teacher
    if (emailLower.contains('teacher') ||
        emailLower.contains('admin') ||
        emailLower.contains('gv') ||
        emailLower.contains('giangvien')) {
      return 'teacher';
    }

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
}