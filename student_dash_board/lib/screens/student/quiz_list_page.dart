// lib/screens/student/quiz_list_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../services/firebase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/camera_permission_dialog.dart';
import 'quiz_taking_page.dart';

class QuizListPage extends StatelessWidget {
  final String studentId;

  const QuizListPage({Key? key, required this.studentId}) : super(key: key);

  void _startQuiz(
    BuildContext context, {
    required String quizId,
    required String quizTitle,
    required int duration,
  }) {
    // On web, show camera permission dialog first
    if (kIsWeb) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CameraPermissionDialog(
          onCameraReady: () {
            // Camera is ready, navigate to quiz
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizTakingPage(
                  quizId: quizId,
                  quizTitle: quizTitle,
                  duration: duration,
                  studentId: studentId,
                ),
              ),
            );
          },
        ),
      );
    } else {
      // On mobile, go directly to quiz (no camera requirement)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizTakingPage(
            quizId: quizId,
            quizTitle: quizTitle,
            duration: duration,
            studentId: studentId,
          ),
        ),
      );
    }
  }

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
                .map(
                  (doc) =>
                      (doc.data() as Map<String, dynamic>)['quizId'] as String,
                )
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
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: AppConstants.successColor,
                    ),
                    SizedBox(height: 20),
                    Text(
                      AppConstants.allQuizzesCompletedMessage,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quiz title
                        Text(
                          data['title'] ?? 'Untitled Quiz',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Quiz info
                        Row(
                          children: [
                            const Icon(
                              Icons.quiz,
                              size: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Số câu: ${data['questionCount'] ?? 0}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 20),
                            const Icon(
                              Icons.timer,
                              size: 20,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${data['duration'] ?? 0} phút',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),

                        // Camera requirement badge (only on web)
                        if (kIsWeb) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam,
                                  size: 16,
                                  color: Colors.red[700],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Yêu cầu bật camera',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Start button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _startQuiz(
                                context,
                                quizId: quiz.id,
                                quizTitle: data['title'] ?? 'Quiz',
                                duration: data['duration'] ?? 30,
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text(
                              AppStrings.start,
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
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
