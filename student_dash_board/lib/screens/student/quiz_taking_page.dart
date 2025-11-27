// lib/screens/student/quiz_taking_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class QuizTakingPage extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final int duration;
  final String studentId;

  const QuizTakingPage({
    Key? key,
    required this.quizId,
    required this.quizTitle,
    required this.duration,
    required this.studentId,
  }) : super(key: key);

  @override
  State<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<QuizTakingPage> {
  Map<String, String> answers = {};
  bool isSubmitting = false;

  late int remainingSeconds;
  late int totalSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    totalSeconds = widget.duration * 60;
    remainingSeconds = totalSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _autoSubmitQuiz();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _remainingPercentage => remainingSeconds / totalSeconds;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await Helpers.showConfirmDialog(
          context,
          title: AppStrings.confirm,
          content: AppConstants.exitConfirmMessage,
          confirmText: AppStrings.exit,
          cancelText: AppStrings.stay,
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quizTitle),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.getQuizQuestions(widget.quizId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('❌ Lỗi: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final questions = snapshot.data!.docs;

            if (questions.isEmpty) {
              return const Center(child: Text('Bài thi này chưa có câu hỏi'));
            }

            return Column(
              children: [
                _buildTimerSection(questions.length),
                const Divider(height: 1),
                _buildProgressBar(questions.length),
                Expanded(
                  child: _buildQuestionsList(questions),
                ),
                _buildSubmitButton(questions),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimerSection(int totalQuestions) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(AppConstants.timerIcon, color: Helpers.getTimerColor(_remainingPercentage)),
                  const SizedBox(width: 8),
                  Text(
                    Helpers.formatTime(remainingSeconds),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Helpers.getTimerColor(_remainingPercentage),
                    ),
                  ),
                ],
              ),
              Text(
                'Đã làm: ${answers.length}/$totalQuestions',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _remainingPercentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Helpers.getTimerColor(_remainingPercentage)),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int totalQuestions) {
    return LinearProgressIndicator(
      value: answers.length / totalQuestions,
      backgroundColor: Colors.grey[300],
      valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
      minHeight: 4,
    );
  }

  Widget _buildQuestionsList(List<QueryDocumentSnapshot> questions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        final data = question.data() as Map<String, dynamic>;
        final options = List<String>.from(data['options'] ?? []);

        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Câu ${index + 1}: ${data['question']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ...options.asMap().entries.map((entry) {
                  final optionIndex = entry.key;
                  final option = entry.value;
                  final optionLabel = Helpers.getOptionLabel(optionIndex);

                  return RadioListTile<String>(
                    title: Text('$optionLabel. $option'),
                    value: optionLabel,
                    groupValue: answers[question.id],
                    onChanged: (value) {
                      setState(() {
                        answers[question.id] = value!;
                      });
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton(List<QueryDocumentSnapshot> questions) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : () => _submitQuiz(questions),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: AppConstants.successColor,
          foregroundColor: Colors.white,
        ),
        child: isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(AppStrings.submit, style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Future<void> _autoSubmitQuiz() async {
    if (isSubmitting) return;

    Helpers.showSnackBar(
      context,
      AppConstants.timeUpMessage,
      backgroundColor: AppConstants.warningColor,
    );

    await Future.delayed(const Duration(seconds: 1));

    final questionsSnapshot = await FirebaseService.getQuizQuestionsOnce(widget.quizId);
    await _submitQuiz(questionsSnapshot.docs, autoSubmit: true);
  }

  Future<void> _submitQuiz(List<QueryDocumentSnapshot> questions, {bool autoSubmit = false}) async {
    if (!autoSubmit && answers.length != questions.length) {
      Helpers.showSnackBar(context, AppConstants.answerAllQuestionsMessage);
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    _timer?.cancel();

    int score = 0;
    for (var question in questions) {
      final data = question.data() as Map<String, dynamic>;
      if (answers[question.id] == data['correctAnswer']) {
        score++;
      }
    }

    await FirebaseService.submitQuiz(
      studentId: widget.studentId,
      quizId: widget.quizId,
      quizTitle: widget.quizTitle,
      score: score,
      totalQuestions: questions.length,
      answers: answers,
      timeSpent: widget.duration * 60 - remainingSeconds,
    );

    if (!mounted) return;

    Navigator.pop(context);
    _showResultDialog(score, questions.length, autoSubmit);
  }

  void _showResultDialog(int score, int total, bool autoSubmit) {
    final percentage = score / total;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(autoSubmit ? '⏰ Hết giờ!' : AppStrings.completed),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              percentage >= AppConstants.excellentScoreThreshold
                  ? AppConstants.trophyIcon
                  : AppConstants.thumbUpIcon,
              size: 60,
              color: percentage >= AppConstants.excellentScoreThreshold
                  ? AppConstants.goldColor
                  : AppConstants.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Điểm của bạn: $score/$total',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${Helpers.getPercentageString(score, total)}%',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }
}