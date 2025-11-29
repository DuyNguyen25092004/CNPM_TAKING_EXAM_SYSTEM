// lib/screens/student/result_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class ResultDetailPage extends StatelessWidget {
  final String submissionId;

  const ResultDetailPage({Key? key, required this.submissionId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.resultDetail),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseService.getSubmissionById(submissionId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final score = data['score'] ?? 0;
          final total = data['totalQuestions'] ?? 1;
          final timeSpent = data['timeSpent'] ?? 0;
          final answers = Map<String, String>.from(data['answers'] ?? {});
          final quizId = data['quizId'] ?? '';

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseService.getQuizQuestionsOnce(quizId),
            builder: (context, questionSnapshot) {
              if (!questionSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final questions = questionSnapshot.data!.docs;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildScoreCard(context, data, score, total, timeSpent),
                  const SizedBox(height: 20),
                  const Text(
                    'Chi tiết câu hỏi và đáp án',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._buildDetailedAnswersList(questions, answers),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScoreCard(
      BuildContext context,
      Map<String, dynamic> data,
      int score,
      int total,
      int timeSpent,
      ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              data['quizTitle'] ?? 'N/A',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      '$score/$total',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    Text(
                      '${Helpers.getPercentageString(score, total)}%',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Icon(AppConstants.timerIcon, size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      Helpers.formatTimeSpent(timeSpent),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Thời gian',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Ngày làm bài: ${Helpers.formatDateTime(data['timestamp'])}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetailedAnswersList(
      List<QueryDocumentSnapshot> questions,
      Map<String, String> answers,
      ) {
    return questions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;
      final questionData = question.data() as Map<String, dynamic>;

      final questionText = questionData['question'] ?? 'N/A';
      final options = List<String>.from(questionData['options'] ?? []);
      final correctAnswer = questionData['correctAnswer'] ?? '';
      final userAnswer = answers[question.id] ?? '';
      final isCorrect = userAnswer == correctAnswer;

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header câu hỏi
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCorrect ? AppConstants.successColor : AppConstants.errorColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Câu ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    isCorrect ? AppConstants.checkCircleIcon : Icons.cancel,
                    color: isCorrect ? AppConstants.successColor : AppConstants.errorColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Câu hỏi
              Text(
                questionText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Danh sách các đáp án
              ...options.asMap().entries.map((optionEntry) {
                final optionIndex = optionEntry.key;
                final option = optionEntry.value;
                final optionLabel = Helpers.getOptionLabel(optionIndex);

                final isCorrectOption = optionLabel == correctAnswer;
                final isUserOption = optionLabel == userAnswer;

                Color? backgroundColor;
                Color? textColor;
                IconData? icon;

                if (isCorrectOption && isUserOption) {
                  // Đáp án đúng và người dùng chọn đúng
                  backgroundColor = Colors.green.shade100;
                  textColor = Colors.green.shade900;
                  icon = AppConstants.checkCircleIcon;
                } else if (isCorrectOption) {
                  // Đáp án đúng nhưng người dùng không chọn
                  backgroundColor = Colors.green.shade100;
                  textColor = Colors.green.shade900;
                  icon = AppConstants.checkCircleIcon;
                } else if (isUserOption) {
                  // Đáp án sai mà người dùng đã chọn
                  backgroundColor = Colors.red.shade100;
                  textColor = Colors.red.shade900;
                  icon = Icons.cancel;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(
                      color: backgroundColor != null
                          ? (isCorrectOption ? Colors.green : Colors.red)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: textColor, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          '$optionLabel. $option',
                          style: TextStyle(
                            fontWeight: (isCorrectOption || isUserOption)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 12),

              // Phần giải thích
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          isCorrect ? 'Bạn đã trả lời đúng!' : 'Giải thích:',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    if (!isCorrect) ...[
                      const SizedBox(height: 8),
                      Text('Đáp án của bạn: $userAnswer'),
                      Text(
                        'Đáp án đúng: $correctAnswer',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.successColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}