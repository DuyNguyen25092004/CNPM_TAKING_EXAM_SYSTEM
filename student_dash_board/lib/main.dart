// ============= FILE: lib/main.dart =============
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth/login_page.dart';
import 'screens/student/student_panel.dart';
import 'screens/teacher/teacher_panel.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Widget tự động đồng bộ Authentication với Firestore
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Đang kiểm tra trạng thái đăng nhập
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang khởi động...'),
                ],
              ),
            ),
          );
        }

        // Chưa đăng nhập
        if (!snapshot.hasData || snapshot.data == null) {
          print('❌ No user logged in');
          return const LoginPage();
        }

        final user = snapshot.data!;
        print('👤 User logged in: ${user.uid}');
        print('📧 Email: ${user.email}');

        // Đã đăng nhập - đồng bộ với Firestore và lấy role
        return FutureBuilder<String?>(
          future: UserService.syncUserAndGetRole(user),
          builder: (context, roleSnapshot) {
            // Đang đồng bộ và lấy role
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Đang đồng bộ dữ liệu...'),
                    ],
                  ),
                ),
              );
            }

            // Có lỗi khi đồng bộ
            if (roleSnapshot.hasError) {
              print('❌ Error syncing: ${roleSnapshot.error}');
              return _buildErrorScreen(
                context,
                title: 'Lỗi đồng bộ',
                message: 'Không thể đồng bộ với máy chủ.\nVui lòng kiểm tra kết nối và thử lại.',
                onRetry: () => (context as Element).markNeedsBuild(),
              );
            }

            final role = roleSnapshot.data;
            print('🎭 Role detected: $role');

            // Không có role hoặc role rỗng
            if (role == null || role.isEmpty) {
              print('⚠️ No role found after sync');
              return _buildErrorScreen(
                context,
                title: 'Không tìm thấy vai trò',
                message: 'Tài khoản chưa được gán vai trò.\nVui lòng liên hệ quản trị viên.',
                showRetry: false,
              );
            }

            // Chuyển hướng dựa trên role
            print('✅ Redirecting to $role panel');

            if (role == 'student') {
              return StudentPanel(studentId: user.uid);
            } else if (role == 'teacher') {
              return const TeacherPanel();
            } else {
              // Role không hợp lệ
              print('⚠️ Invalid role: $role');
              return _buildErrorScreen(
                context,
                title: 'Vai trò không hợp lệ',
                message: 'Vai trò "$role" không được hỗ trợ.\nVui lòng liên hệ quản trị viên.',
                showRetry: false,
              );
            }
          },
        );
      },
    );
  }

  /// Widget hiển thị màn hình lỗi
  Widget _buildErrorScreen(
      BuildContext context, {
        required String title,
        required String message,
        VoidCallback? onRetry,
        bool showRetry = true,
      }) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.orange[300],
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Nút thử lại
              if (showRetry && onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),

              if (showRetry && onRetry != null)
                const SizedBox(height: 16),

              // Nút đăng xuất
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  await UserService.clearUserCache();
                },
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}