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
        title: const Text('Chi tiết kết quả'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
          final percentage = ((score / total) * 100).toStringAsFixed(0);
          final answers = Map<String, String>.from(data['answers'] ?? {});
          final quizId = data['quizId'] ?? '';

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseService.getQuizQuestionsOnce(quizId),
            builder: (context, questionSnapshot) {
              if (!questionSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final questions = questionSnapshot.data!.docs;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScoreCard(context, data, score, total, percentage),
                    const SizedBox(height: 24),
                    Text('Chi tiết từng câu hỏi', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ..._buildDetailedAnswersList(questions, answers),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, Map<String, dynamic> data, int score, int total, String percentage) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.primaryColor, AppConstants.primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            data['quizTitle'] ?? 'Bài thi',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreStat('Điểm', '$score/$total', Colors.white),
              Container(width: 1, height: 60, color: Colors.white30),
              _buildScoreStat('Phần trăm', '$percentage%', Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ngày làm bài: ${Helpers.formatDateTime(data['timestamp'])}',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
      ],
    );
  }

  List<Widget> _buildDetailedAnswersList(List<QueryDocumentSnapshot> questions, Map<String, String> answers) {
    return questions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;
      final questionData = question.data() as Map<String, dynamic>;

      final questionText = questionData['question'] ?? 'N/A';
      final options = List<String>.from(questionData['options'] ?? []);
      final correctAnswer = questionData['correctAnswer'] ?? '';
      final userAnswer = answers[question.id] ?? '';
      final isCorrect = userAnswer == correctAnswer;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border.all(color: isCorrect ? Colors.green.shade300 : Colors.red.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Câu ${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red, size: 20),
                  const Spacer(),
                  Text(isCorrect ? 'Đúng' : 'Sai', style: TextStyle(fontWeight: FontWeight.w600, color: isCorrect ? Colors.green : Colors.red)),
                ],
              ),
              const SizedBox(height: 12),
              Text(questionText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ...options.asMap().entries.map((optionEntry) {
                final optionIndex = optionEntry.key;
                final option = optionEntry.value;
                final optionLabel = Helpers.getOptionLabel(optionIndex);

                final isCorrectOption = optionLabel == correctAnswer;
                final isUserOption = optionLabel == userAnswer;
                final shouldHighlight = isCorrectOption || isUserOption;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: shouldHighlight ? (isCorrectOption ? Colors.green.shade100 : Colors.red.shade100) : Colors.transparent,
                    border: Border.all(
                      color: shouldHighlight ? (isCorrectOption ? Colors.green : Colors.red) : Colors.grey.shade300,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (shouldHighlight) ...[
                        Icon(isCorrectOption ? Icons.check_circle : Icons.cancel, size: 18, color: isCorrectOption ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                      ],
                      Expanded(child: Text('$optionLabel. $option', style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      );
    }).toList();
  }
}