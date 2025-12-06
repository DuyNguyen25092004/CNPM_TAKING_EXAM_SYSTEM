// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ CLASS OPERATIONS (MỚI) ============

  // Lấy danh sách lớp học của học sinh
  static Stream<QuerySnapshot> getStudentClasses(String studentId) {
    return _firestore
        .collection('classes')
        .where('studentIds', arrayContains: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Lấy thông tin lớp học
  static Future<DocumentSnapshot> getClassById(String classId) {
    return _firestore.collection('classes').doc(classId).get();
  }

  // ============ QUIZ OPERATIONS ============

  // Stream available quizzes (cũ - giữ lại để tương thích)
  static Stream<QuerySnapshot> getAvailableQuizzes() {
    return _firestore
        .collection('quiz')
        .where('status', isEqualTo: 'available')
        .snapshots();
  }

  // Lấy danh sách bài thi của lớp (MỚI)
  static Stream<QuerySnapshot> getClassQuizzes(String classId) {
    return _firestore
        .collection('quiz')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
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

  // Stream submissions by student (cũ - giữ lại để tương thích)
  static Stream<QuerySnapshot> getStudentSubmissions(String studentId) {
    return _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .snapshots();
  }

  // Lấy bài nộp của học sinh trong lớp cụ thể (MỚI)
  static Stream<QuerySnapshot> getStudentClassSubmissions(
      String studentId, String classId) {
    return _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .where('classId', isEqualTo: classId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Stream recent submissions (for dashboard) - cũ
  static Stream<QuerySnapshot> getRecentSubmissions(String studentId, {int limit = 5}) {
    return _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Lấy hoạt động gần đây của học sinh trong lớp (MỚI)
  static Stream<QuerySnapshot> getRecentClassSubmissions(
      String studentId, String classId, {int limit = 5}) {
    return _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .where('classId', isEqualTo: classId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get submission by ID
  static Future<DocumentSnapshot> getSubmissionById(String submissionId) {
    return _firestore.collection('submissions').doc(submissionId).get();
  }

  // Submit quiz answers (CẬP NHẬT - thêm classId)
  static Future<void> submitQuiz({
    required String studentId,
    required String quizId,
    String? classId, // Thêm optional để tương thích với code cũ
    required String quizTitle,
    required int score,
    required int totalQuestions,
    required Map<String, String> answers,
    required int timeSpent,
  }) {
    final data = {
      'studentId': studentId,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'score': score,
      'totalQuestions': totalQuestions,
      'answers': answers,
      'timestamp': FieldValue.serverTimestamp(),
      'timeSpent': timeSpent,
    };

    // Chỉ thêm classId nếu có
    if (classId != null) {
      data['classId'] = classId;
    }

    return _firestore.collection('submissions').add(data);
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

  // Check if student has completed a quiz in a specific class (MỚI)
  static Future<bool> hasCompletedQuizInClass(
      String studentId, String quizId, String classId) async {
    final result = await _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .where('quizId', isEqualTo: quizId)
        .where('classId', isEqualTo: classId)
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

    return snapshot.docs
        .map((doc) => (doc.data()['quizId'] as String))
        .toSet();
  }

  // Get completed quiz IDs for a student in a specific class (MỚI)
  static Future<Set<String>> getCompletedQuizIdsInClass(
      String studentId, String classId) async {
    final snapshot = await _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .where('classId', isEqualTo: classId)
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['quizId'] as String))
        .toSet();
  }
}