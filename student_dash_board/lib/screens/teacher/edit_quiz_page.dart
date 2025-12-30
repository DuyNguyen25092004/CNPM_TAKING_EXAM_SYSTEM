// lib/screens/teacher/edit_quiz_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditQuizPage extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> quizData;

  const EditQuizPage({Key? key, required this.quizId, required this.quizData})
    : super(key: key);

  @override
  State<EditQuizPage> createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late TextEditingController _maxViolationsController; // ADDED

  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quizData['title']);
    _durationController = TextEditingController(
      text: widget.quizData['duration'].toString(),
    );
    // ADDED: Initialize with existing value or default to 5
    _maxViolationsController = TextEditingController(
      text: (widget.quizData['maxSuspiciousActions'] ?? 5).toString(),
    );
    _loadQuestions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _maxViolationsController.dispose(); // ADDED
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('quiz')
          .doc(widget.quizId)
          .collection('questions')
          .get();

      final sortedDocs = questionsSnapshot.docs.toList();
      sortedDocs.sort((a, b) {
        final orderA = a.data()['order'] as int?;
        final orderB = b.data()['order'] as int?;
        if (orderA != null && orderB != null) {
          return orderA.compareTo(orderB);
        }
        return 0;
      });

      setState(() {
        _questions = sortedDocs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'question': data['question'] ?? '',
            'options': List<String>.from(data['options'] ?? []),
            'correctAnswer': data['correctAnswer'] ?? 'A',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi khi tải câu hỏi: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade50,
              Colors.white,
              Colors.yellow.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.orange.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chỉnh sửa đề thi',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Cập nhật thông tin và câu hỏi',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.save_rounded,
                              color: Colors.green.shade700,
                            ),
                            tooltip: 'Lưu thay đổi',
                            onPressed: _isSaving ? null : _saveQuiz,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.orange.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Đang tải câu hỏi...'),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quiz info card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.info_outline,
                                            color: Colors.orange.shade700,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Thông tin đề thi',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _titleController,
                                      decoration: InputDecoration(
                                        labelText: 'Tên đề thi',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        prefixIcon: const Icon(Icons.title),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Vui lòng nhập tên đề thi';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _durationController,
                                      decoration: InputDecoration(
                                        labelText: 'Thời gian làm bài (phút)',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        prefixIcon: const Icon(Icons.timer),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Vui lòng nhập thời gian';
                                        }
                                        final duration = int.tryParse(value);
                                        if (duration == null || duration <= 0) {
                                          return 'Thời gian phải là số dương';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    // ADDED: Max Violations field
                                    TextFormField(
                                      controller: _maxViolationsController,
                                      decoration: InputDecoration(
                                        labelText: 'Số lần vi phạm tối đa',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.warning_amber_rounded,
                                        ),
                                        hintText: '5',
                                        helperText:
                                            'Học sinh sẽ tự động nộp bài sau khi vi phạm đủ số lần',
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Vui lòng nhập số lần vi phạm';
                                        }
                                        final maxViolations = int.tryParse(
                                          value,
                                        );
                                        if (maxViolations == null ||
                                            maxViolations < 1) {
                                          return 'Số lần vi phạm phải ≥ 1';
                                        }
                                        if (maxViolations > 20) {
                                          return 'Số lần vi phạm không nên > 20';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Questions header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.quiz,
                                          color: Colors.blue.shade700,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Câu hỏi (${_questions.length})',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _addNewQuestion,
                                    icon: const Icon(Icons.add, size: 20),
                                    label: const Text('Thêm câu hỏi'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Questions list
                              ..._questions.asMap().entries.map((entry) {
                                final index = entry.key;
                                final question = entry.value;
                                return _buildQuestionCard(index, question);
                              }).toList(),

                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveQuiz,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
              backgroundColor: Colors.green.shade600,
            ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> question) {
    final options = question['options'] as List<String>;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Câu ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_rounded,
                      color: Colors.red.shade700,
                    ),
                    onPressed: () => _deleteQuestion(index),
                    tooltip: 'Xóa câu hỏi',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Question text
            TextFormField(
              initialValue: question['question'],
              decoration: InputDecoration(
                labelText: 'Nội dung câu hỏi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.help_outline),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  _questions[index]['question'] = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập câu hỏi';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Options
            // Options
            // Trong widget _buildQuestionCard
            // Trong widget _buildQuestionCard
            ...List.generate(options.length, (optionIndex) {
              final letter = String.fromCharCode(65 + optionIndex);

              // Lấy dữ liệu đáp án hiện tại
              final rawCorrect = question['correctAnswer'];

              // Kiểm tra xem đang là Multiple (List) hay Single (String)
              bool isMultiple = rawCorrect is List;
              bool isSelected = false;

              // Logic kiểm tra xem ô này có được chọn không
              if (isMultiple) {
                isSelected = (rawCorrect as List)
                    .map((e) => e.toString())
                    .contains(letter);
              } else {
                isSelected = rawCorrect.toString() == letter;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: isMultiple
                          ? Checkbox(
                              value: isSelected,
                              activeColor: Colors.green,
                              onChanged: (val) {
                                setState(() {
                                  // --- FIX LỖI CRASH Ở ĐÂY ---
                                  // Phải xử lý trường hợp rawCorrect đang là String
                                  List<String> currentAnswers;
                                  if (rawCorrect is List) {
                                    currentAnswers = List<String>.from(
                                      rawCorrect,
                                    );
                                  } else {
                                    // Nếu đang là String (VD: "A"), chuyển thành List ["A"]
                                    currentAnswers = [rawCorrect.toString()];
                                  }

                                  if (val == true) {
                                    if (!currentAnswers.contains(letter)) {
                                      currentAnswers.add(letter);
                                    }
                                    currentAnswers.sort();
                                  } else {
                                    currentAnswers.remove(letter);
                                  }

                                  _questions[index]['correctAnswer'] =
                                      currentAnswers;
                                  _questions[index]['type'] = 'multiple';
                                });
                              },
                            )
                          : Radio<String>(
                              value: letter,
                              groupValue: rawCorrect
                                  .toString(), // Chuyển về string để so sánh an toàn
                              activeColor: Colors.green,
                              onChanged: (val) {
                                setState(() {
                                  _questions[index]['correctAnswer'] = val!;
                                  _questions[index]['type'] = 'single';
                                });
                              },
                            ),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: options[optionIndex],
                        decoration: InputDecoration(
                          labelText: 'Đáp án $letter',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              // --- ĐÃ SỬA: Dùng biến isSelected thay vì isCorrect ---
                              color: isSelected
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          filled: true,
                          // --- ĐÃ SỬA: Dùng biến isSelected thay vì isCorrect ---
                          fillColor: isSelected
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.shade50,
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              // --- ĐÃ SỬA: Dùng biến isSelected thay vì isCorrect ---
                              color: isSelected
                                  ? Colors.green
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                letter,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _questions[index]['options'][optionIndex] = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập đáp án';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            // ✨ Hiển thị đáp án đúng
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Đáp án đúng: ${question['correctAnswer'] is List ? (question['correctAnswer'] as List).join(", ") : question['correctAnswer']}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewQuestion() {
    setState(() {
      _questions.add({
        'id': null,
        'question': '',
        'options': ['', '', '', ''],
        'correctAnswer': 'A',
      });
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red.shade50, Colors.white],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red.shade700,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Xác nhận xóa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn có chắc muốn xóa câu ${index + 1}?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _questions.removeAt(index);
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text('Đã xóa câu hỏi'),
                              ],
                            ),
                            backgroundColor: Colors.green.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Xóa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Vui lòng kiểm tra lại thông tin'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Validate questions
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      if (question['question'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Câu ${i + 1} chưa có nội dung'),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      final options = question['options'] as List<String>;
      if (options.any((opt) => opt.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Câu ${i + 1} chưa đủ 4 đáp án'),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final quizRef = FirebaseFirestore.instance
          .collection('quiz')
          .doc(widget.quizId);

      // MODIFIED: Update quiz with maxSuspiciousActions
      await quizRef.update({
        'title': _titleController.text.trim(),
        'duration': int.parse(_durationController.text),
        'maxSuspiciousActions': int.parse(
          _maxViolationsController.text,
        ), // ADDED
        'questionCount': _questions.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final existingQuestions = await quizRef.collection('questions').get();
      for (var doc in existingQuestions.docs) {
        await doc.reference.delete();
      }

      for (var question in _questions) {
        await quizRef.collection('questions').add({
          'question': question['question'].toString().trim(),
          'options': (question['options'] as List<String>)
              .map((opt) => opt.trim())
              .toList(),
          'correctAnswer': question['correctAnswer'],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã lưu thay đổi thành công!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi khi lưu: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
