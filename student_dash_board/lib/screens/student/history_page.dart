// lib/screens/student/history_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'result_detail_page.dart';

class HistoryPage extends StatelessWidget {
  final String studentId;

  const HistoryPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getStudentSubmissions(studentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Lỗi History: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(AppConstants.errorIcon, size: 60, color: AppConstants.errorColor),
                const SizedBox(height: 10),
                Text('Lỗi: ${snapshot.error}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Reload page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryPage(studentId: studentId),
                      ),
                    );
                  },
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppConstants.historyIcon, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  AppConstants.noQuizzesMessage,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Sort submissions by timestamp (client-side)
        final sortedDocs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime); // Descending order
          });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final submission = sortedDocs[index];
            final data = submission.data() as Map<String, dynamic>;

            final score = data['score'] ?? 0;
            final total = data['totalQuestions'] ?? 1;
            final percentage = Helpers.getPercentageString(score, total);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Helpers.getScoreColor(score / total),
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(data['quizTitle'] ?? 'N/A'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Điểm số: $score/$total'),
                    Text(Helpers.formatDateTime(data['timestamp'])),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(AppConstants.visibilityIcon),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultDetailPage(
                          submissionId: submission.id,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}