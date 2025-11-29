// ============= FILE: lib/services/user_service.dart =============
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lưu vai trò của user vào Firestore VÀ SharedPreferences
  static Future<void> setUserRole(String userId, String role) async {
    try {
      print('Setting role for user: $userId, role: $role');

      // Lưu vào SharedPreferences (local storage)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      await prefs.setString('user_id', userId);
      print('Role saved to SharedPreferences');

      // Lưu vào Firestore (nếu có thể)
      try {
        await _firestore.collection('users').doc(userId).set({
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('Role saved to Firestore');
      } catch (e) {
        print('Could not save to Firestore (might not be configured): $e');
        // Không throw error, vì SharedPreferences đã lưu thành công
      }
    } catch (e) {
      print('Error setting user role: $e');
      rethrow;
    }
  }

  // Lấy vai trò của user từ SharedPreferences HOẶC Firestore
  static Future<String?> getUserRole(String userId) async {
    try {
      print('Getting role for user: $userId');

      // Thử lấy từ SharedPreferences trước (nhanh hơn)
      final prefs = await SharedPreferences.getInstance();
      final localRole = prefs.getString('user_role');
      final localUserId = prefs.getString('user_id');

      if (localRole != null && localUserId == userId) {
        print('User role from SharedPreferences: $localRole');
        return localRole;
      }

      // Nếu không có trong SharedPreferences, thử Firestore
      print('Trying Firestore...');
      final doc = await _firestore.collection('users').doc(userId).get();
      print('Document exists: ${doc.exists}');
      if (doc.exists) {
        final role = doc.data()?['role'] as String?;
        print('User role from Firestore: $role');

        // Lưu vào SharedPreferences cho lần sau
        if (role != null) {
          await prefs.setString('user_role', role);
          await prefs.setString('user_id', userId);
        }

        return role;
      }

      print('No role found anywhere');
      return null;
    } catch (e) {
      print('Error getting user role: $e');

      // Nếu Firestore lỗi, vẫn thử lấy từ SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final localRole = prefs.getString('user_role');
        if (localRole != null) {
          print(
              'Returning role from SharedPreferences despite error: $localRole');
          return localRole;
        }
      } catch (_) {}

      return null;
    }
  }

  // Xóa vai trò khi đăng xuất
  static Future<void> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_id');
  }
}