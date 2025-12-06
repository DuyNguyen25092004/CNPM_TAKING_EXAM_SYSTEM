// lib/screens/teacher/teacher_panel.dart (UPDATED)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_quiz_page.dart';
import 'manage_quizzes_page.dart';
import 'view_results_page.dart';
import 'manage_classes_page.dart';
import '../auth/login_page.dart';

class TeacherPanel extends StatefulWidget {
  const TeacherPanel({Key? key}) : super(key: key);

  @override
  State<TeacherPanel> createState() => _TeacherPanelState();
}

class _TeacherPanelState extends State<TeacherPanel> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Widget> _pages = const [
    ManageClassesPage(), // New: Manage Classes
    ManageQuizzesPage(),
    CreateQuizPage(),
    ViewResultsPage(),
  ];

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            SizedBox(width: 8),
            Text('Đăng xuất'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await _auth.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi đăng xuất: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Panel'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.class_),
            label: 'Lớp học',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz),
            label: 'Đề thi',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle),
            label: 'Tạo đề',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment),
            label: 'Kết quả',
          ),
        ],
      ),
    );
  }
}