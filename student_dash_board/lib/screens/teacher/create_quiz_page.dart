// lib/screens/teacher/create_quiz_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({Key? key}) : super(key: key);

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tạo Đề thi mới',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Instructions card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Hướng dẫn định dạng file',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'File PDF hoặc TXT phải có định dạng:\n\n'
                      'Câu 1: Thủ đô Việt Nam là?\n'
                      'A. Hà Nội\n'
                      'B. Đà Nẵng\n'
                      'C. TP.HCM\n'
                      'D. Hải Phòng\n'
                      'Đáp án: A\n\n'
                      'Câu 2: 2 + 2 = ?\n'
                      'A. 2\n'
                      'B. 3\n'
                      'C. 4\n'
                      'D. 5\n'
                      'Đáp án: C',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quiz title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên đề thi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                hintText: 'VD: Kiểm tra Toán học Lớp 10',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên đề thi';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Duration
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Thời gian làm bài (phút)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
                hintText: '30',
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

            const SizedBox(height: 24),

            // Upload button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadQuiz,
                icon: const Icon(Icons.upload_file, size: 28),
                label: const Text(
                  'Upload File PDF/TXT',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            if (_isUploading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Center(
                child: Text('Đang xử lý: ${(_uploadProgress * 100).toInt()}%'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _uploadQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
        withData: true,
      );

      if (result == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.2;
      });

      final fileName = result.files.single.name;
      final bytes = result.files.single.bytes;

      if (bytes == null) {
        throw Exception('Không thể đọc file');
      }

      // Extract text from file
      String content = '';
      if (fileName.endsWith('.txt')) {
        content = String.fromCharCodes(bytes);
      } else if (fileName.endsWith('.pdf')) {
        content = await _extractTextFromPdf(bytes);
      }

      if (content.isEmpty) {
        throw Exception('File trống hoặc không đọc được nội dung');
      }

      setState(() => _uploadProgress = 0.5);

      // Parse questions
      final questions = _parseQuestions(content);

      if (questions.isEmpty) {
        throw Exception(
          'Không tìm thấy câu hỏi nào!\n\n'
          'Vui lòng kiểm tra định dạng file.',
        );
      }

      setState(() => _uploadProgress = 0.7);

      // Create quiz document
      final quizRef = await FirebaseFirestore.instance.collection('quiz').add({
        'title': _titleController.text.trim(),
        'questionCount': questions.length,
        'duration': int.parse(_durationController.text),
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add questions to subcollection
      for (var question in questions) {
        await quizRef.collection('questions').add(question);
      }

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Tạo đề thi thành công!\nĐã thêm ${questions.length} câu hỏi',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Reset form
        _titleController.clear();
        _durationController.text = '30';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<String> _extractTextFromPdf(List<int> bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('Lỗi khi đọc PDF: $e');
    }
  }

  List<Map<String, dynamic>> _parseQuestions(String content) {
    List<Map<String, dynamic>> questions = [];

    final questionPattern = RegExp(
      r'Câu\s+(\d+):\s*(.+?)\s*A\.\s*(.+?)\s*B\.\s*(.+?)\s*C\.\s*(.+?)\s*D\.\s*(.+?)\s*Đáp án:\s*([A-D])',
      multiLine: true,
      dotAll: true,
    );

    final matches = questionPattern.allMatches(content);

    for (var match in matches) {
      questions.add({
        'question': match.group(2)!.trim(),
        'options': [
          match.group(3)!.trim(),
          match.group(4)!.trim(),
          match.group(5)!.trim(),
          match.group(6)!.trim(),
        ],
        'correctAnswer': match.group(7)!.trim(),
      });
    }

    return questions;
  }
}
