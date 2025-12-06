// lib/screens/student/quiz_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';
import 'quiz_taking_page.dart';

class QuizListPage extends StatelessWidget {
  final String studentId;
  final String classId;

  const QuizListPage({
    Key? key,
    required this.studentId,
    required this.classId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getClassQuizzes(classId),
      builder: (context, quizSnapshot) {
        if (quizSnapshot.hasError) {
          return _buildErrorWidget(quizSnapshot.error);
        }

        if (!quizSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.getStudentClassSubmissions(studentId, classId),
          builder: (context, submissionSnapshot) {
            if (!submissionSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final completedQuizIds = submissionSnapshot.data!.docs
                .map((doc) => (doc.data() as Map<String, dynamic>)['quizId'] as String)
                .toSet();

            final availableQuizzes = quizSnapshot.data!.docs
                .where((quiz) => !completedQuizIds.contains(quiz.id))
                .toList();

            if (availableQuizzes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.celebration, size: 80, color: Colors.green.shade300),
                    const SizedBox(height: 16),
                    const Text('Bạn đã hoàn thành tất cả bài thi!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('${index + 1}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                      ),
                    ),
                    title: Text(
                      data['title'] ?? 'Bài thi chưa được đặt tên',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.help_outline, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text('${data['questionCount'] ?? 0} câu hỏi', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                            const SizedBox(width: 12),
                            Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text('${data['duration'] ?? 0} phút', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => QuizTakingPage(
                            quizId: quiz.id,
                            classId: classId,
                            quizTitle: data['title'] ?? 'Quiz',
                            duration: data['duration'] ?? 30,
                            studentId: studentId,
                          )),
                        );
                      },
                      child: const Text('Làm bài', style: TextStyle(color: Colors.white, fontSize: 12)),
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

  Widget _buildErrorWidget(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Lỗi: $error', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}