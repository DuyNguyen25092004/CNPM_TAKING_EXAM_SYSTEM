// lib/screens/teacher/class_results_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassResultsPage extends StatefulWidget {
  final String classId;

  const ClassResultsPage({Key? key, required this.classId}) : super(key: key);

  @override
  State<ClassResultsPage> createState() => _ClassResultsPageState();
}

class _ClassResultsPageState extends State<ClassResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedQuizFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kết quả thi của lớp',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo mã học sinh...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
              const SizedBox(height: 12),
              // Quiz filter
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(widget.classId)
                    .collection('quizzes')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final quizzes = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: _selectedQuizFilter,
                    decoration: InputDecoration(
                      labelText: 'Lọc theo bài thi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tất cả bài thi'),
                      ),
                      ...quizzes.map((quiz) {
                        final data = quiz.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: quiz.id,
                          child: Text(data['title'] ?? 'Bài thi'),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedQuizFilter = value);
                    },
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('submissions')
                .where('classId', isEqualTo: widget.classId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Lỗi: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 100,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có bài thi nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              var submissions = snapshot.data!.docs;

              // Filter by search
              if (_searchQuery.isNotEmpty) {
                submissions = submissions.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final studentId =
                  (data['studentId'] ?? '').toString().toLowerCase();
                  return studentId.contains(_searchQuery);
                }).toList();
              }

              // Filter by quiz
              if (_selectedQuizFilter != null) {
                submissions = submissions.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['quizId'] == _selectedQuizFilter;
                }).toList();
              }

              if (submissions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 100,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy kết quả',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final doc = submissions[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final score = data['score'] ?? 0;
                  final total = data['totalQuestions'] ?? 1;
                  final percentage = (score / total * 100);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: _getScoreColor(percentage),
                        child: Text(
                          '$score/$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Text(
                        'HS: ${data['studentId'] ?? 'Unknown'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(data['quizTitle'] ?? 'N/A'),
                          const SizedBox(height: 4),
                          Text(
                            'Điểm: ${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: _getScoreColor(percentage),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(data['timestamp']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'Xem chi tiết',
                        onPressed: () {
                          _showSubmissionDetail(context, doc.id, data);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _showSubmissionDetail(
      BuildContext context,
      String submissionId,
      Map<String, dynamic> submission,
      ) async {
    final quizId = submission['quizId'] as String?;

    if (quizId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Không tìm thấy thông tin đề thi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final questionsSnapshot = await FirebaseFirestore.instance
        .collection('quiz')
        .doc(quizId)
        .collection('questions')
        .get();

    if (!context.mounted) return;

    if (questionsSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Không tìm thấy câu hỏi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final studentAnswers = submission['answers'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => _SubmissionDetailDialog(
        submission: submission,
        questions: questionsSnapshot.docs,
        studentAnswers: studentAnswers,
      ),
    );
  }
}

class _SubmissionDetailDialog extends StatelessWidget {
  final Map<String, dynamic> submission;
  final List<QueryDocumentSnapshot> questions;
  final Map<String, dynamic> studentAnswers;

  const _SubmissionDetailDialog({
    required this.submission,
    required this.questions,
    required this.studentAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final score = submission['score'] ?? 0;
    final total = submission['totalQuestions'] ?? 1;
    final percentage = (score / total * 100);
    final timeSpent = submission['timeSpent'] ?? 0;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chi tiết bài thi - ${submission['studentId']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        submission['quizTitle'] ?? 'N/A',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getScoreColor(percentage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getScoreColor(percentage)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildScoreStat(
                    icon: Icons.check_circle,
                    label: 'Đúng',
                    value: '$score',
                    color: Colors.green,
                  ),
                  _buildScoreStat(
                    icon: Icons.cancel,
                    label: 'Sai',
                    value: '${total - score}',
                    color: Colors.red,
                  ),
                  _buildScoreStat(
                    icon: Icons.percent,
                    label: 'Điểm',
                    value: '${percentage.toStringAsFixed(1)}%',
                    color: _getScoreColor(percentage),
                  ),
                  _buildScoreStat(
                    icon: Icons.timer,
                    label: 'Thời gian',
                    value: _formatTime(timeSpent),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final questionDoc = questions[index];
                  final questionData = questionDoc.data() as Map<String, dynamic>;
                  final questionId = questionDoc.id;
                  final correctAnswer = questionData['correctAnswer'] ?? '';
                  final studentAnswer = studentAnswers[questionId] ?? '';
                  final isCorrect = studentAnswer == correctAnswer;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCorrect ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  isCorrect ? Icons.check : Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Câu ${index + 1}: ${questionData['question']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          ...List.generate(4, (i) {
                            final letter = String.fromCharCode(65 + i);
                            final options = questionData['options'] as List;
                            final isCorrectOption = letter == correctAnswer;
                            final isStudentChoice = letter == studentAnswer;

                            Color? backgroundColor;
                            Color? borderColor;
                            IconData? icon;

                            if (isCorrectOption) {
                              backgroundColor = Colors.green.shade100;
                              borderColor = Colors.green;
                              icon = Icons.check_circle;
                            } else if (isStudentChoice && !isCorrect) {
                              backgroundColor = Colors.red.shade100;
                              borderColor = Colors.red;
                              icon = Icons.cancel;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: backgroundColor ?? Colors.grey.shade50,
                                border: Border.all(
                                  color: borderColor ?? Colors.grey.shade300,
                                  width: (isCorrectOption || isStudentChoice) ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isStudentChoice || isCorrectOption
                                          ? (isCorrectOption ? Colors.green : Colors.red)
                                          : Colors.grey,
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
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(options[i])),
                                  if (icon != null)
                                    Icon(
                                      icon,
                                      color: isCorrectOption ? Colors.green : Colors.red,
                                    ),
                                ],
                              ),
                            );
                          }),

                          if (!isCorrect) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      studentAnswer.isEmpty
                                          ? 'Học sinh chưa trả lời'
                                          : 'Học sinh chọn: $studentAnswer (Sai)',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}