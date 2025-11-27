// lib/screens/teacher/edit_quiz_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    _loadQuestions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('quiz')
          .doc(widget.quizId)
          .collection('questions')
          .get();

      // Sort by order if available
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
            content: Text('Lỗi khi tải câu hỏi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa đề thi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveQuiz,
            tooltip: 'Lưu thay đổi',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quiz info card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin đề thi',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Tên đề thi',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.title),
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
                              decoration: const InputDecoration(
                                labelText: 'Thời gian làm bài (phút)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.timer),
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
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Questions header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Câu hỏi (${_questions.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addNewQuestion,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm câu hỏi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
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
      floatingActionButton: FloatingActionButton.extended(
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
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Câu ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteQuestion(index),
                  tooltip: 'Xóa câu hỏi',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Question text
            TextFormField(
              initialValue: question['question'],
              decoration: const InputDecoration(
                labelText: 'Nội dung câu hỏi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.help_outline),
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
            ...List.generate(4, (optionIndex) {
              final letter = String.fromCharCode(65 + optionIndex);
              final options = question['options'] as List<String>;
              final isCorrect = question['correctAnswer'] == letter;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<String>(
                      value: letter,
                      groupValue: question['correctAnswer'],
                      onChanged: (value) {
                        setState(() {
                          _questions[index]['correctAnswer'] = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: options[optionIndex],
                        decoration: InputDecoration(
                          labelText: 'Đáp án $letter',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: isCorrect ? Colors.green : Colors.grey,
                              width: isCorrect ? 2 : 1,
                            ),
                          ),
                          filled: isCorrect,
                          fillColor: isCorrect
                              ? Colors.green.withOpacity(0.1)
                              : null,
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

            const SizedBox(height: 8),

            // Correct answer indicator
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Đáp án đúng: ${question['correctAnswer']}',
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
        'id': null, // New question, no ID yet
        'question': '',
        'options': ['', '', '', ''],
        'correctAnswer': 'A',
      });
    });

    // Scroll to bottom
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
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa câu ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _questions.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã xóa câu hỏi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng kiểm tra lại thông tin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if all questions have valid data
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      if (question['question'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Câu ${i + 1} chưa có nội dung'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final options = question['options'] as List<String>;
      if (options.any((opt) => opt.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Câu ${i + 1} chưa đủ 4 đáp án'),
            backgroundColor: Colors.orange,
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

      // Update quiz info
      await quizRef.update({
        'title': _titleController.text.trim(),
        'duration': int.parse(_durationController.text),
        'questionCount': _questions.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get existing questions
      final existingQuestions = await quizRef.collection('questions').get();

      // Delete all existing questions
      for (var doc in existingQuestions.docs) {
        await doc.reference.delete();
      }

      // Add updated questions
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
          const SnackBar(
            content: Text('✅ Đã lưu thay đổi thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi lưu: $e'),
            backgroundColor: Colors.red,
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
