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
      // const SubmitQuizPage(),
      HistoryPage(studentId: widget.studentId),
    ];
  }

  void navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.studentPanelTitle),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          navigateToTab(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(AppConstants.dashboardIcon),
            label: AppStrings.dashboard,
          ),
          NavigationDestination(
            icon: Icon(AppConstants.quizIcon),
            label: AppStrings.quizList,
          ),
          // NavigationDestination(
          //   icon: Icon(AppConstants.uploadIcon),
          //   label: AppStrings.submitQuiz,
          // ),
          NavigationDestination(
            icon: Icon(AppConstants.historyIcon),
            label: AppStrings.history,
          ),
        ],
      ),
    );
  }
}
