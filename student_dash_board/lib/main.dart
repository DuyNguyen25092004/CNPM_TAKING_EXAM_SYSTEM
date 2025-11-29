// ============= FILE: lib/main.dart =============
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/role_selection_page.dart';
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

// Widget kiểm tra trạng thái đăng nhập và vai trò
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
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Chưa đăng nhập - hiển thị màn hình chọn vai trò
        if (!snapshot.hasData || snapshot.data == null) {
          return const RoleSelectionPage();
        }

        final user = snapshot.data!;
        print('👤 User logged in: ${user.uid}');

        // Đã đăng nhập - kiểm tra vai trò và chuyển hướng
        return FutureBuilder<String?>(
          future: UserService.getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            // Đang load role
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Đang tải thông tin...'),
                    ],
                  ),
                ),
              );
            }

            // Kiểm tra lỗi
            if (roleSnapshot.hasError) {
              print('❌ Error loading role: ${roleSnapshot.error}');
              // Nếu có lỗi Firestore, mặc định vào student panel
              return StudentPanel(studentId: user.uid);
            }

            final role = roleSnapshot.data;
            print('🎭 User role: $role');

            // Chuyển hướng dựa trên role
            if (role == 'student') {
              print('✅ Redirecting to StudentPanel');
              return StudentPanel(studentId: user.uid);
            } else if (role == 'teacher') {
              print('✅ Redirecting to TeacherPanel');
              return const TeacherPanel();
            } else {
              // Vai trò null hoặc không xác định
              // Mặc định vào student panel thay vì yêu cầu chọn lại
              print('⚠️ No role found, defaulting to StudentPanel');
              return StudentPanel(studentId: user.uid);
            }
          },
        );
      },
    );
  }
}
