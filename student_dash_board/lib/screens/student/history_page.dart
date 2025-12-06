// lib/screens/student/history_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'result_detail_page.dart';

class HistoryPage extends StatelessWidget {
  final String studentId;
  final String classId;

  const HistoryPage({
    Key? key,
    required this.studentId,
    required this.classId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getStudentClassSubmissions(studentId, classId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error);
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('Chưa có lịch sử làm bài', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        final sortedDocs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            return bTime?.compareTo(aTime ?? Timestamp.now()) ?? 0;
          });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final submission = sortedDocs[index];
            final data = submission.data() as Map<String, dynamic>;

            final score = data['score'] ?? 0;
            final total = data['totalQuestions'] ?? 1;
            final percentage = ((score / total) * 100).toStringAsFixed(0);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getScoreBgColor(double.parse(percentage)),
                  ),
                  child: Center(
                    child: Text(
                      '$percentage%',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                title: Text(data['quizTitle'] ?? 'Bài thi', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('$score/$total điểm', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    Text(Helpers.formatDateTime(data['timestamp']), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ResultDetailPage(submissionId: submission.id)),
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

  Color _getScoreBgColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
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