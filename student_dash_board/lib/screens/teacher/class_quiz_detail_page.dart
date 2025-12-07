// lib/screens/teacher/class_quiz_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../teacher/edit_quiz_page.dart';

class ClassQuizDetailPage extends StatelessWidget {
  final String classId;
  final String quizId;
  final Map<String, dynamic> quizData;

  const ClassQuizDetailPage({
    Key? key,
    required this.classId,
    required this.quizId,
    required this.quizData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quizData['title'] ?? 'Chi tiết bài thi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Chỉnh sửa',
            onPressed: () => _editQuiz(context),
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('quiz')
            .doc(quizId)
            .collection('questions')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Không có câu hỏi nào'),
            );
          }

          final questions = snapshot.data!.docs;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quiz info card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin đề thi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.quiz, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text('Số câu hỏi: ${quizData['questionCount']}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text('Thời gian: ${quizData['duration']} phút'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Danh sách câu hỏi:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Questions list
                ...questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final questionData =
                  entry.value.data() as Map<String, dynamic>;
                  final options =
                  List<String>.from(questionData['options'] ?? []);
                  final correctAnswer = questionData['correctAnswer'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Câu ${index + 1}: ${questionData['question']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...options.asMap().entries.map((optEntry) {
                            final letter =
                            String.fromCharCode(65 + optEntry.key);
                            final isCorrect = letter == correctAnswer;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? Colors.green.shade50
                                    : Colors.grey.shade50,
                                border: Border.all(
                                  color: isCorrect ? Colors.green : Colors.grey,
                                  width: isCorrect ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color:
                                      isCorrect ? Colors.green : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        letter,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(optEntry.value)),
                                  if (isCorrect)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _editQuiz(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditQuizPage(
          quizId: quizId,
          quizData: quizData,
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đề thi đã được cập nhật'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh page
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClassQuizDetailPage(
            classId: classId,
            quizId: quizId,
            quizData: quizData,
          ),
        ),
      );
    }
  }
}