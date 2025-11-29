// lib/screens/student/student_panel.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'dashboard_page.dart';
import 'quiz_list_page.dart';
// import 'submit_quiz_page.dart';
import 'history_page.dart';

class StudentPanel extends StatefulWidget {
  final String studentId;

  const StudentPanel({Key? key, required this.studentId}) : super(key: key);

  @override
  State<StudentPanel> createState() => StudentPanelState();
}

class StudentPanelState extends State<StudentPanel> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(studentId: widget.studentId),
      QuizListPage(studentId: widget.studentId),
      HistoryPage(studentId: widget.studentId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Học Tập'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Bài thi',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
        ],
      ),
    );
  }
}