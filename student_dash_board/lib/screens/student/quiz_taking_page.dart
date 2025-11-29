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
  int currentQuestionIndex = 0;

  late int remainingSeconds;
  late int totalSeconds;
  Timer? _timer;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    totalSeconds = widget.duration * 60;
    remainingSeconds = totalSeconds;
    _pageController = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        _timer?.cancel();
        _autoSubmitQuiz();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await Helpers.showConfirmDialog(
          context,
          title: 'Thoát bài thi?',
          content: 'Bạn chắc chắn muốn thoát? Bài thi sẽ không được lưu.',
          confirmText: 'Thoát',
          cancelText: 'Tiếp tục',
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quizTitle),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.getQuizQuestions(widget.quizId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error);
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
                _buildProgressSection(questions.length),
                _buildTimerBar(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => currentQuestionIndex = index),
                    itemCount: questions.length,
                    itemBuilder: (context, index) => _buildQuestionCard(questions[index], index, questions.length),
                  ),
                ),
                _buildNavigationBar(questions.length),
                _buildSubmitSection(questions.length),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressSection(int totalQuestions) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Câu ${currentQuestionIndex + 1}/$totalQuestions', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${answers.length}/$totalQuestions đã trả lời', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / totalQuestions,
              minHeight: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    final isTimeWarning = remainingSeconds < 300;
    final isTimeCritical = remainingSeconds < 60;
    final timeColor = isTimeCritical ? Colors.red : (isTimeWarning ? Colors.orange : AppConstants.primaryColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: timeColor.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: timeColor.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: timeColor, size: 20),
          const SizedBox(width: 8),
          Text(
            Helpers.formatTime(remainingSeconds),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: timeColor),
          ),
          const Spacer(),
          if (isTimeWarning) Text('Vội vàng lên!', style: TextStyle(color: timeColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QueryDocumentSnapshot question, int index, int total) {
    final data = question.data() as Map<String, dynamic>;
    final options = List<String>.from(data['options'] ?? []);
    final isAnswered = answers.containsKey(question.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['question'] ?? 'Câu hỏi không được tải',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 24),
          ...options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final option = entry.value;
            final optionLabel = Helpers.getOptionLabel(optionIndex);
            final isSelected = answers[question.id] == optionLabel;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppConstants.primaryColor : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? AppConstants.primaryColor.withOpacity(0.05) : Colors.white,
              ),
              child: RadioListTile<String>(
                title: Text('$optionLabel. $option', style: const TextStyle(fontSize: 16)),
                value: optionLabel,
                groupValue: answers[question.id],
                onChanged: (value) {
                  setState(() => answers[question.id] = value!);
                },
                activeColor: AppConstants.primaryColor,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(int totalQuestions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: currentQuestionIndex == 0 ? null : () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Trước'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.black),
          ),
          const Spacer(),
          Text('${currentQuestionIndex + 1} / $totalQuestions', style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: currentQuestionIndex == totalQuestions - 1 ? null : () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Tiếp'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitSection(int totalQuestions) {
    final isAllAnswered = answers.length == totalQuestions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : () => _submitQuiz(totalQuestions),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: isAllAnswered ? AppConstants.primaryColor : Colors.grey,
          ),
          child: isSubmitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
            isAllAnswered ? 'Nộp bài' : 'Trả lời tất cả câu hỏi (${answers.length}/$totalQuestions)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _autoSubmitQuiz() async {
    if (isSubmitting) return;
    Helpers.showSnackBar(context, 'Hết giờ! Bài thi sẽ được nộp tự động.', backgroundColor: Colors.orange);
    await Future.delayed(const Duration(seconds: 1));
    final questionsSnapshot = await FirebaseService.getQuizQuestionsOnce(widget.quizId);
    await _submitQuiz(questionsSnapshot.docs.length, autoSubmit: true);
  }

  Future<void> _submitQuiz(int totalQuestions, {bool autoSubmit = false}) async {
    if (!autoSubmit && answers.length != totalQuestions) {
      Helpers.showSnackBar(context, 'Vui lòng trả lời tất cả các câu hỏi');
      return;
    }

    setState(() => isSubmitting = true);
    _timer?.cancel();

    final questionsSnapshot = await FirebaseService.getQuizQuestionsOnce(widget.quizId);
    int score = 0;

    for (var question in questionsSnapshot.docs) {
      final data = question.data() as Map<String, dynamic>;
      if (answers[question.id] == data['correctAnswer']) score++;
    }

    await FirebaseService.submitQuiz(
      studentId: widget.studentId,
      quizId: widget.quizId,
      quizTitle: widget.quizTitle,
      score: score,
      totalQuestions: questionsSnapshot.docs.length,
      answers: answers,
      timeSpent: widget.duration * 60 - remainingSeconds,
    );

    if (!mounted) return;

    Navigator.pop(context);
    _showResultDialog(score, questionsSnapshot.docs.length, autoSubmit);
  }

  void _showResultDialog(int score, int total, bool autoSubmit) {
    final percentage = (score / total * 100).toStringAsFixed(0);
    final isPassed = score / total >= 0.6;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPassed ? Colors.green.shade100 : Colors.orange.shade100,
                ),
                child: Icon(
                  isPassed ? Icons.check_circle : Icons.info_outline,
                  size: 40,
                  color: isPassed ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                autoSubmit ? 'Hết giờ!' : 'Hoàn thành!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                isPassed ? 'Bạn đã vượt qua bài thi!' : 'Cố gắng lần sau nhé!',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text('$score/$total', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                    Text('$percentage% điểm', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
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
