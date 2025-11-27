// lib/screens/student/analytics_page.dart
import 'package:flutter/material.dart';

import '../../services/analytics_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class AnalyticsPage extends StatelessWidget {
  final String studentId;

  const AnalyticsPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentAnalytics>(
      future: AnalyticsService.calculateStudentAnalytics(studentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final analytics = snapshot.data!;

        if (analytics.totalQuizzes == 0) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'Chưa có dữ liệu phân tích',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(
                  'Hãy hoàn thành một số bài thi để xem phân tích',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildOverviewCard(context, analytics),
            const SizedBox(height: 16),
            _buildPerformanceBreakdown(context, analytics),
            const SizedBox(height: 16),
            _buildImprovementCard(context, analytics),
            const SizedBox(height: 16),
            _buildTimeAnalysisCard(context, analytics),
            const SizedBox(height: 16),
            _buildPerformanceTrend(context),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard(BuildContext context, StudentAnalytics analytics) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: AppConstants.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  'Tổng quan',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 30),
            _buildStatRow(
              'Tổng số bài thi:',
              '${analytics.totalQuizzes}',
              Icons.quiz,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Điểm trung bình:',
              '${analytics.averageScore.toStringAsFixed(1)}',
              Icons.grade,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Tỷ lệ đúng TB:',
              '${analytics.averagePercentage.toStringAsFixed(1)}%',
              Icons.percent,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Thời gian TB/bài:',
              Helpers.formatTimeSpent(analytics.averageTimePerQuiz.toInt()),
              Icons.timer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBreakdown(
    BuildContext context,
    StudentAnalytics analytics,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.pie_chart,
                  color: AppConstants.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  'Phân loại kết quả',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 30),
            _buildPerformanceBar(
              context,
              'Xuất sắc (≥80%)',
              analytics.excellentCount,
              analytics.totalQuizzes,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildPerformanceBar(
              context,
              'Khá (65-79%)',
              analytics.goodCount,
              analytics.totalQuizzes,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildPerformanceBar(
              context,
              'Trung bình (50-64%)',
              analytics.averageCount,
              analytics.totalQuizzes,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildPerformanceBar(
              context,
              'Yếu (<50%)',
              analytics.poorCount,
              analytics.totalQuizzes,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBar(
    BuildContext context,
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(
              '$count/${total}',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildImprovementCard(
    BuildContext context,
    StudentAnalytics analytics,
  ) {
    final isImproving = analytics.improvementRate > 0;
    final color = isImproving ? Colors.green : Colors.orange;
    final icon = isImproving ? Icons.trending_up : Icons.trending_down;

    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              isImproving ? 'Bạn đang tiến bộ!' : 'Cần cố gắng thêm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${analytics.improvementRate.abs().toStringAsFixed(1)}% ${isImproving ? 'tăng' : 'giảm'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'So sánh giữa nửa đầu và nửa sau kết quả',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAnalysisCard(
    BuildContext context,
    StudentAnalytics analytics,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: AppConstants.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  'Phân tích thời gian',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 30),
            FutureBuilder<Map<String, dynamic>>(
              future: AnalyticsService.getTimeAnalysis(studentId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final timeData = snapshot.data!;
                return Column(
                  children: [
                    _buildTimeRow(
                      'Tổng thời gian:',
                      Helpers.formatTimeSpent(timeData['totalTime']),
                      Icons.timelapse,
                    ),
                    const SizedBox(height: 12),
                    _buildTimeRow(
                      'Trung bình/bài:',
                      Helpers.formatTimeSpent(timeData['averageTime'].toInt()),
                      Icons.timer_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildTimeRow(
                      'Nhanh nhất:',
                      Helpers.formatTimeSpent(timeData['fastestQuiz']),
                      Icons.speed,
                    ),
                    const SizedBox(height: 12),
                    _buildTimeRow(
                      'Chậm nhất:',
                      Helpers.formatTimeSpent(timeData['slowestQuiz']),
                      Icons.hourglass_bottom,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPerformanceTrend(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.show_chart,
                  color: AppConstants.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  'xu hướng (10 bài gần nhất)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 30),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: AnalyticsService.getPerformanceTrend(studentId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final trend = snapshot.data!;

                if (trend.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Chưa có dữ liệu xu hướng'),
                    ),
                  );
                }

                return Column(
                  children: trend.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    final percentage = data['percentage'] as int;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['quizTitle'],
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Helpers.getScoreColor(percentage / 100),
                                    ),
                                    minHeight: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '$percentage%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Helpers.getScoreColor(percentage / 100),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
