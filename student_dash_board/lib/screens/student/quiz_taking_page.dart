// lib/screens/student/quiz_taking_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizTakingPage extends StatefulWidget {
  final String quizId;
  final String classId;
  final String quizTitle;
  final int duration;
  final String studentId; // Đã thêm tham số này

  const QuizTakingPage({
    Key? key,
    required this.quizId,
    required this.classId,
    required this.quizTitle,
    required this.duration,
    required this.studentId, // Đã thêm vào constructor
  }) : super(key: key);

  @override
  State<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<QuizTakingPage> {
  final PageController _pageController = PageController();

  // State variables
  int _currentIndex = 0;
  int _secondsRemaining = 0;
  Timer? _timer;
  bool _isSubmitting = false;
  bool _isLoading = true;

  // Data
  List<QueryDocumentSnapshot> _questions = [];
  // Map lưu câu trả lời: { "questionId": "A" }
  final Map<String, String> _answers = {};

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.duration * 60;
    _loadQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _forceSubmit();
      }
    });
  }

  Future<void> _loadQuestions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quiz')
          .doc(widget.quizId)
          .collection('questions')
          .get();

      setState(() {
        _questions = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải câu hỏi: $e')),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _selectAnswer(String questionId, String answer) {
    setState(() {
      _answers[questionId] = answer;
    });
  }

  void _jumpToQuestion(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
    Navigator.pop(context); // Đóng drawer
  }

  @override
  Widget build(BuildContext context) {
    final isTimeRunningOut = _secondsRemaining < 300;

    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn không thể thoát khi đang làm bài! Hãy nộp bài trước.')),
        );
        return false;
      },
      child: Scaffold(
        endDrawer: _buildQuestionPaletteDrawer(),

        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header Custom
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Timer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isTimeRunningOut ? Colors.red.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isTimeRunningOut ? Colors.red.shade200 : Colors.blue.shade200
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                                Icons.timer_outlined,
                                size: 18,
                                color: isTimeRunningOut ? Colors.red : Colors.blue
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(_secondsRemaining),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isTimeRunningOut ? Colors.red : Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Nút mở bảng câu hỏi
                      Builder(
                        builder: (context) => InkWell(
                          onTap: () => Scaffold.of(context).openEndDrawer(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.grid_view_rounded, size: 20, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  '${_answers.length}/${_questions.length} câu',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Nút nộp bài
                      ElevatedButton(
                        onPressed: _confirmSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Nộp bài'),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: Colors.blue.shade600))
                      : PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      return _buildQuestionPage(index);
                    },
                  ),
                ),

                // Footer Navigation
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Previous Button
                        TextButton.icon(
                          onPressed: _currentIndex > 0
                              ? () {
                            setState(() => _currentIndex--);
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                              : null,
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Câu trước'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),

                        // Next Button
                        ElevatedButton.icon(
                          onPressed: _currentIndex < _questions.length - 1
                              ? () {
                            setState(() => _currentIndex++);
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                              : _confirmSubmit,
                          icon: Icon(_currentIndex < _questions.length - 1
                              ? Icons.arrow_forward_rounded
                              : Icons.check_circle_outline),
                          label: Text(_currentIndex < _questions.length - 1
                              ? 'Câu sau'
                              : 'Hoàn thành'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentIndex < _questions.length - 1
                                ? Colors.blue.shade50
                                : Colors.green.shade600,
                            foregroundColor: _currentIndex < _questions.length - 1
                                ? Colors.blue.shade700
                                : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage(int index) {
    final doc = _questions[index];
    final data = doc.data() as Map<String, dynamic>;
    final questionId = doc.id;
    final options = List<String>.from(data['options'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Câu ${index + 1}',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '/${_questions.length}',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  data['question'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          ...List.generate(4, (i) {
            final letter = String.fromCharCode(65 + i);
            final isSelected = _answers[questionId] == letter;

            return GestureDetector(
              onTap: () => _selectAnswer(questionId, letter),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade400 : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        options.length > i ? options[i] : '',
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? Colors.blue.shade900 : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: Colors.blue.shade600),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuestionPaletteDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.grid_view_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tổng quan bài thi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildLegendItem(Colors.blue.shade600, 'Đã làm'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.grey.shade300, 'Chưa làm'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.orange.shade400, 'Đang chọn', isBorder: true),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final questionId = _questions[index].id;
                final isAnswered = _answers.containsKey(questionId);
                final isCurrent = index == _currentIndex;

                return InkWell(
                  onTap: () => _jumpToQuestion(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isAnswered
                          ? Colors.blue.shade600
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrent
                          ? Border.all(color: Colors.orange.shade400, width: 3)
                          : Border.all(color: Colors.transparent),
                      boxShadow: isAnswered ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isAnswered ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã hoàn thành:',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      '${_answers.length} / ${_questions.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmSubmit();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Nộp bài thi', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool isBorder = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isBorder ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: isBorder ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nộp bài?'),
        content: Text(
            'Bạn đã làm ${_answers.length}/${_questions.length} câu hỏi.\n'
                'Bạn có chắc chắn muốn nộp bài không?'
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kiểm tra lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _forceSubmit();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
            child: const Text('Nộp ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _forceSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      int score = 0;

      for (var doc in _questions) {
        final data = doc.data() as Map<String, dynamic>;
        final qId = doc.id;
        final correctAnswer = data['correctAnswer'];
        final studentAnswer = _answers[qId];

        if (studentAnswer == correctAnswer) {
          score++;
        }
      }

      await FirebaseFirestore.instance.collection('submissions').add({
        'studentId': widget.studentId, // Đã sửa: dùng studentId được truyền vào
        'quizId': widget.quizId,
        'classId': widget.classId,
        'quizTitle': widget.quizTitle,
        'answers': _answers,
        'score': score,
        'totalQuestions': _questions.length,
        'timestamp': FieldValue.serverTimestamp(),
        'timeSpent': (widget.duration * 60) - _secondsRemaining,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nộp bài thành công! Điểm số: $score/${_questions.length}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi nộp bài: $e')),
        );
      }
    }
  }
}