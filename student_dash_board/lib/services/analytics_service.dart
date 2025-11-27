// lib/services/analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentAnalytics {
  final double averageScore;
  final double averagePercentage;
  final int totalQuizzes;
  final int excellentCount;
  final int goodCount;
  final int averageCount;
  final int poorCount;
  final double improvementRate;
  final String strongestTopic;
  final String weakestTopic;
  final int totalTimeSpent;
  final double averageTimePerQuiz;

  StudentAnalytics({
    required this.averageScore,
    required this.averagePercentage,
    required this.totalQuizzes,
    required this.excellentCount,
    required this.goodCount,
    required this.averageCount,
    required this.poorCount,
    required this.improvementRate,
    required this.strongestTopic,
    required this.weakestTopic,
    required this.totalTimeSpent,
    required this.averageTimePerQuiz,
  });
}

class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculate comprehensive analytics for a student
  static Future<StudentAnalytics> calculateStudentAnalytics(
    String studentId,
  ) async {
    // 🔥 FIX: Remove orderBy to avoid composite index requirement
    final submissions = await _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .get();

    if (submissions.docs.isEmpty) {
      return StudentAnalytics(
        averageScore: 0,
        averagePercentage: 0,
        totalQuizzes: 0,
        excellentCount: 0,
        goodCount: 0,
        averageCount: 0,
        poorCount: 0,
        improvementRate: 0,
        strongestTopic: 'N/A',
        weakestTopic: 'N/A',
        totalTimeSpent: 0,
        averageTimePerQuiz: 0,
      );
    }

    // 🔥 FIX: Sort in memory instead of using orderBy
    final sortedDocs = submissions.docs;
    sortedDocs.sort((a, b) {
      final aTime =
          (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bTime =
          (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return aTime.compareTo(bTime);
    });

    // Calculate basic stats
    int totalScore = 0;
    int totalQuestions = 0;
    int excellentCount = 0;
    int goodCount = 0;
    int averageCount = 0;
    int poorCount = 0;
    int totalTimeSpent = 0;

    List<double> percentages = [];

    for (var doc in sortedDocs) {
      final data = doc.data();
      final score = data['score'] ?? 0;
      final total = data['totalQuestions'] ?? 1;
      final timeSpent = data['timeSpent'] ?? 0;

      totalScore += score as int;
      totalQuestions += total as int;
      totalTimeSpent += timeSpent as int;

      final percentage = score / total;
      percentages.add(percentage);

      // Categorize performance
      if (percentage >= 0.8) {
        excellentCount++;
      } else if (percentage >= 0.65) {
        goodCount++;
      } else if (percentage >= 0.5) {
        averageCount++;
      } else {
        poorCount++;
      }
    }

    // Calculate improvement rate (comparing first half vs second half)
    double improvementRate = 0;
    if (percentages.length >= 4) {
      final midPoint = percentages.length ~/ 2;
      final firstHalf = percentages.sublist(0, midPoint);
      final secondHalf = percentages.sublist(midPoint);

      final avgFirstHalf = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final avgSecondHalf =
          secondHalf.reduce((a, b) => a + b) / secondHalf.length;

      improvementRate = ((avgSecondHalf - avgFirstHalf) / avgFirstHalf) * 100;
    }

    return StudentAnalytics(
      averageScore: totalScore / sortedDocs.length,
      averagePercentage: (totalScore / totalQuestions) * 100,
      totalQuizzes: sortedDocs.length,
      excellentCount: excellentCount,
      goodCount: goodCount,
      averageCount: averageCount,
      poorCount: poorCount,
      improvementRate: improvementRate,
      strongestTopic: 'Toán học', // TODO: Implement topic analysis
      weakestTopic: 'Văn học', // TODO: Implement topic analysis
      totalTimeSpent: totalTimeSpent,
      averageTimePerQuiz: totalTimeSpent / sortedDocs.length,
    );
  }

  // Get performance trend data (last 10 quizzes)
  static Future<List<Map<String, dynamic>>> getPerformanceTrend(
    String studentId,
  ) async {
    // 🔥 FIX: Remove orderBy, sort in memory
    final submissions = await _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .get();

    // Sort by timestamp
    final sortedDocs = submissions.docs;
    sortedDocs.sort((a, b) {
      final aTime =
          (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bTime =
          (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return aTime.compareTo(bTime);
    });

    // Take last 10
    final last10 = sortedDocs.length > 10
        ? sortedDocs.sublist(sortedDocs.length - 10)
        : sortedDocs;

    return last10.map((doc) {
      final data = doc.data();
      return {
        'quizTitle': data['quizTitle'] ?? 'N/A',
        'percentage':
            ((data['score'] ?? 0) / (data['totalQuestions'] ?? 1) * 100)
                .toInt(),
        'timestamp': data['timestamp'],
      };
    }).toList();
  }

  // Get time spent analysis
  static Future<Map<String, dynamic>> getTimeAnalysis(String studentId) async {
    final submissions = await _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .get();

    if (submissions.docs.isEmpty) {
      return {
        'totalTime': 0,
        'averageTime': 0,
        'fastestQuiz': 0,
        'slowestQuiz': 0,
      };
    }

    List<int> times = submissions.docs
        .map((doc) => (doc.data()['timeSpent'] ?? 0) as int)
        .toList();

    times.sort();

    return {
      'totalTime': times.reduce((a, b) => a + b),
      'averageTime': times.reduce((a, b) => a + b) / times.length,
      'fastestQuiz': times.first,
      'slowestQuiz': times.last,
    };
  }

  // Get accuracy rate per quiz
  static Future<Map<String, double>> getAccuracyByQuiz(String studentId) async {
    final submissions = await _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .get();

    Map<String, List<double>> quizScores = {};

    for (var doc in submissions.docs) {
      final data = doc.data();
      final quizTitle = data['quizTitle'] ?? 'N/A';
      final percentage = (data['score'] ?? 0) / (data['totalQuestions'] ?? 1);

      if (!quizScores.containsKey(quizTitle)) {
        quizScores[quizTitle] = [];
      }
      quizScores[quizTitle]!.add(percentage);
    }

    Map<String, double> averages = {};
    quizScores.forEach((title, scores) {
      averages[title] = (scores.reduce((a, b) => a + b) / scores.length) * 100;
    });

    return averages;
  }
}
