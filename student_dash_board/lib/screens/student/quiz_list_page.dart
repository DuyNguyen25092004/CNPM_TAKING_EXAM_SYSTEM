// lib/screens/student/quiz_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';
import 'quiz_taking_page.dart';

class QuizListPage extends StatelessWidget {
  final String studentId;

  const QuizListPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getAvailableQuizzes(),
      builder: (context, quizSnapshot) {
        if (quizSnapshot.hasError) {
          return Center(child: Text('❌ Lỗi: ${quizSnapshot.error}'));
        }

        if (!quizSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.getStudentSubmissions(studentId),
          builder: (context, submissionSnapshot) {
            if (!submissionSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Lấy danh sách quiz đã làm
            final completedQuizIds = submissionSnapshot.data!.docs
                .map((doc) => (doc.data() as Map<String, dynamic>)['quizId'] as String)
                .toSet();

            // Lọc ra những quiz chưa làm
            final availableQuizzes = quizSnapshot.data!.docs
                .where((quiz) => !completedQuizIds.contains(quiz.id))
                .toList();

            if (availableQuizzes.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 80, color: AppConstants.successColor),
                    SizedBox(height: 20),
                    Text(
                      AppConstants.allQuizzesCompletedMessage,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableQuizzes.length,
              itemBuilder: (context, index) {
                final quiz = availableQuizzes[index];
                final data = quiz.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      data['title'] ?? 'Untitled Quiz',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('Số câu hỏi: ${data['questionCount'] ?? 0}'),
                        Text('Thời gian: ${data['duration'] ?? 0} phút'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizTakingPage(
                              quizId: quiz.id,
                              quizTitle: data['title'] ?? 'Quiz',
                              duration: data['duration'] ?? 30,
                              studentId: studentId,
                            ),
                          ),
                        );
                      },
                      child: const Text(AppStrings.start),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}