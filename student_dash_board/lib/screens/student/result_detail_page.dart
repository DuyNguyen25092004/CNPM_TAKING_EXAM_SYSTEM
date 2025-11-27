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
          final answers = data['answers'] as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildScoreCard(context, data, score, total, timeSpent),
              const SizedBox(height: 20),
              const Text(
                AppStrings.yourAnswers,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._buildAnswersList(answers),
            ],
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
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 10),
            Text(
              '${AppStrings.timeSpent}: ${Helpers.formatTimeSpent(timeSpent)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnswersList(Map<String, dynamic> answers) {
    return answers.entries.map((entry) {
      return Card(
        child: ListTile(
          title: Text('Câu hỏi ${entry.key}'),
          subtitle: Text('Đáp án: ${entry.value}'),
        ),
      );
    }).toList();
  }
}