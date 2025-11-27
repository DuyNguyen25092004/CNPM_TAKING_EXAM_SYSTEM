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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(AppConstants.errorIcon, size: 60, color: AppConstants.errorColor),
                const SizedBox(height: 10),
                Text('Lỗi: ${quizSnapshot.error}'),
              ],
            ),
          );
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

            // Lọc quiz chưa làm
            final availableQuizzes = quizSnapshot.data!.docs
                .where((quiz) => !completedQuizIds.contains(quiz.id))
                .length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAvailableQuizzesCard(context, availableQuizzes),
                const SizedBox(height: 20),
                Text(
                  AppConstants.highlightsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                _buildRecentSubmissions(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAvailableQuizzesCard(BuildContext context, int count) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(AppConstants.quizIcon, size: 60, color: AppConstants.primaryColor),
            const SizedBox(height: 10),
            Text(
              AppConstants.availableQuizzesTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSubmissions() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getRecentSubmissions(studentId, limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(AppStrings.loading),
            ),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(AppConstants.noSubmissionsMessage),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(AppConstants.checkCircleIcon, color: AppConstants.successColor),
                title: Text('Bài thi: ${data['quizTitle'] ?? 'N/A'}'),
                subtitle: Text('${AppStrings.score}: ${data['score'] ?? 0}/${data['totalQuestions'] ?? 0}'),
                trailing: Text(
                  Helpers.formatDate(data['timestamp']),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}