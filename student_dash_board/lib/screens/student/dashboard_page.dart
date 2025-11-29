// lib/screens/student/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class DashboardPage extends StatelessWidget {
  final String studentId;

  const DashboardPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getAvailableQuizzes(),
      builder: (context, quizSnapshot) {
        if (quizSnapshot.hasError) {
          return _buildErrorWidget(quizSnapshot.error);
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

            final completedQuizIds = submissionSnapshot.data!.docs
                .map((doc) => (doc.data() as Map<String, dynamic>)['quizId'] as String)
                .toSet();

            final availableQuizzes = quizSnapshot.data!.docs
                .where((quiz) => !completedQuizIds.contains(quiz.id))
                .length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(context, availableQuizzes, submissionSnapshot.data!.docs.length),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Hoạt động gần đây'),
                  const SizedBox(height: 12),
                  _buildRecentSubmissions(studentId),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsCard(BuildContext context, int available, int completed) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.primaryColor, AppConstants.primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppConstants.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('Chưa làm', available.toString(), Icons.assignment_outlined, Colors.white),
            Container(width: 1, height: 60, color: Colors.white30),
            _buildStatItem('Đã hoàn thành', completed.toString(), Icons.check_circle_outline, Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildRecentSubmissions(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getRecentSubmissions(studentId, limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingCard();
        }

        if (snapshot.data!.docs.isEmpty) {
          return _buildEmptyCard('Chưa có hoạt động');
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                title: Text(data['quizTitle'] ?? 'Bài thi', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('$score/$total điểm'),
                trailing: Text(
                  Helpers.formatDate(data['timestamp']),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _getScoreBgColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(message, style: TextStyle(color: Colors.grey.shade600))),
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