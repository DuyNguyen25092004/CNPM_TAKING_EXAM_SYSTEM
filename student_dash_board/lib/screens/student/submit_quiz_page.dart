// lib/screens/student/submit_quiz_page.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'student_panel.dart';

class SubmitQuizPage extends StatelessWidget {
  const SubmitQuizPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 80, color: AppConstants.primaryColor),
            const SizedBox(height: 20),
            const Text(
              'Nộp bài tự động',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bài thi của bạn sẽ được nộp và chấm điểm tự động khi:\n• Bạn hoàn thành tất cả câu hỏi\n• Hết thời gian làm bài',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final panel = context.findAncestorStateOfType<StudentPanelState>();
                panel?.navigateToTab(1); // Navigate to Quiz List tab
              },
              child: const Text('Đi tới làm bài thi'),
            ),
          ],
        ),
      ),
    );
  }
}