// lib/screens/teacher/teacher_panel.dart
import 'package:flutter/material.dart';
import 'create_quiz_page.dart';
import 'manage_quizzes_page.dart';
import 'view_results_page.dart';

class TeacherPanel extends StatefulWidget {
  const TeacherPanel({Key? key}) : super(key: key);

  @override
  State<TeacherPanel> createState() => _TeacherPanelState();
}

class _TeacherPanelState extends State<TeacherPanel> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    ManageQuizzesPage(),
    CreateQuizPage(),
    ViewResultsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Panel'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.quiz),
            label: 'Quản lý Đề thi',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle),
            label: 'Tạo Đề thi',
          ),
          NavigationDestination(icon: Icon(Icons.assessment), label: 'Kết quả'),
        ],
      ),
    );
  }
}
