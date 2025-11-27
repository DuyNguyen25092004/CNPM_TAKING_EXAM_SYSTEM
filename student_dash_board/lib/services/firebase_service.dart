// lib/services/firebase_service.dart (Updated with anti-cheat support)
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ QUIZ OPERATIONS ============

  // Stream available quizzes
  static Stream<QuerySnapshot> getAvailableQuizzes() {
    return _firestore
        .collection('quiz')
        .where('status', isEqualTo: 'available')
        .snapshots();
  }

  // Get quiz by ID
  static Future<DocumentSnapshot> getQuizById(String quizId) {
    return _firestore.collection('quiz').doc(quizId).get();
  }

  // Get questions for a quiz
  static Stream<QuerySnapshot> getQuizQuestions(String quizId) {
    return _firestore
        .collection('quiz')
        .doc(quizId)
        .collection('questions')
        .snapshots();
  }

  static Future<QuerySnapshot> getQuizQuestionsOnce(String quizId) {
    return _firestore
        .collection('quiz')
        .doc(quizId)
        .collection('questions')
        .get();
  }

  // ============ SUBMISSION OPERATIONS ============

  // Stream submissions by student
  static Stream<QuerySnapshot> getStudentSubmissions(String studentId) {
    return _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .snapshots();
  }

  // Stream recent submissions (for dashboard)
  static Stream<QuerySnapshot> getRecentSubmissions(
    String studentId, {
    int limit = 5,
  }) {
    return _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get submission by ID
  static Future<DocumentSnapshot> getSubmissionById(String submissionId) {
    return _firestore.collection('submissions').doc(submissionId).get();
  }

  // Submit quiz answers (returns DocumentReference for anti-cheat update)
  static Future<DocumentReference> submitQuiz({
    required String studentId,
    required String quizId,
    required String quizTitle,
    required int score,
    required int totalQuestions,
    required Map<String, String> answers,
    required int timeSpent,
  }) {
    return _firestore.collection('submissions').add({
      'studentId': studentId,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'score': score,
      'totalQuestions': totalQuestions,
      'answers': answers,
      'timestamp': FieldValue.serverTimestamp(),
      'timeSpent': timeSpent,
    });
  }

  // Check if student has completed a quiz
  static Future<bool> hasCompletedQuiz(String studentId, String quizId) async {
    final result = await _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .where('quizId', isEqualTo: quizId)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  // Get completed quiz IDs for a student
  static Future<Set<String>> getCompletedQuizIds(String studentId) async {
    final snapshot = await _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .get();

    return snapshot.docs.map((doc) => (doc.data()['quizId'] as String)).toSet();
  }

  // ============ ANTI-CHEAT OPERATIONS ============

  // Get submissions with anti-cheat flags
  static Stream<QuerySnapshot> getFlaggedSubmissions() {
    return _firestore
        .collection('submissions')
        .where('antiCheat.flagged', isEqualTo: true)
        .snapshots();
  }

  // Get suspicious activities for a student
  static Future<QuerySnapshot> getSuspiciousActivities(String studentId) {
    return _firestore
        .collection('suspicious_activities')
        .where('studentId', isEqualTo: studentId)
        .orderBy('timestamp', descending: true)
        .get();
  }

  // Get suspicious activities for a submission
  static Future<QuerySnapshot> getSubmissionActivities(String submissionId) {
    return _firestore
        .collection('suspicious_activities')
        .where('submissionId', isEqualTo: submissionId)
        .orderBy('timestamp', descending: true)
        .get();
  }
}
