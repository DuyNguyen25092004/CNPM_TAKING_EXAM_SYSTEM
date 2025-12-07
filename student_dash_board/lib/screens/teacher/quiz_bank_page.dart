// lib/screens/teacher/quiz_bank_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_bank_create_page.dart';
import 'edit_quiz_page.dart';

class QuizBankPage extends StatefulWidget {
  const QuizBankPage({Key? key}) : super(key: key);

  @override
  State<QuizBankPage> createState() => _QuizBankPageState();
}

class _QuizBankPageState extends State<QuizBankPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, available, archived

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.purple.shade600],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.library_books, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kho đề thi',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Quản lý tất cả đề thi của bạn',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuizBankCreatePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 24),
                  label: const Text(
                    'Tạo đề thi mới',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple.shade700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search and Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm đề thi...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
              // Status filter chips
              Row(
                children: [
                  const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Tất cả', 'all', Colors.blue),
                          const SizedBox(width: 8),
                          _buildFilterChip('Đang mở', 'available', Colors.green),
                          const SizedBox(width: 8),
                          _buildFilterChip('Đã đóng', 'archived', Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Quiz List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('quiz')
                .orderBy('createdAt', descending: true)
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
                        Icons.quiz_outlined,
                        size: 100,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có đề thi nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhấn "Tạo đề thi mới" để bắt đầu',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              var quizzes = snapshot.data!.docs;

              // Filter by search
              if (_searchQuery.isNotEmpty) {
                quizzes = quizzes.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery);
                }).toList();
              }

              // Filter by status
              if (_statusFilter != 'all') {
                quizzes = quizzes.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == _statusFilter;
                }).toList();
              }

              if (quizzes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 100, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy đề thi',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  final quiz = quizzes[index];
                  final data = quiz.data() as Map<String, dynamic>;

                  return _buildQuizCard(quiz.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _statusFilter = value);
      },
      backgroundColor: Colors.white,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildQuizCard(String quizId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'available';
    final isAvailable = status == 'available';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${data['questionCount'] ?? 0}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
                Text(
                  'câu',
                  style: TextStyle(
                    fontSize: 11,
                    color: isAvailable ? Colors.green.shade600 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        title: Text(
          data['title'] ?? 'Untitled',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${data['duration'] ?? 0} phút'),
                const SizedBox(width: 16),
                Icon(
                  isAvailable ? Icons.lock_open : Icons.lock,
                  size: 16,
                  color: isAvailable ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  isAvailable ? 'Đang mở' : 'Đã đóng',
                  style: TextStyle(
                    color: isAvailable ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('Xem chi tiết'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa', style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(
                    isAvailable ? Icons.lock : Icons.lock_open,
                    size: 20,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAvailable ? 'Đóng đề thi' : 'Mở đề thi',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            switch (value) {
              case 'view':
                _viewQuizDetails(quizId, data);
                break;
              case 'edit':
                _editQuiz(quizId, data);
                break;
              case 'toggle_status':
                _toggleQuizStatus(quizId, data);
                break;
              case 'delete':
                _deleteQuiz(quizId, data);
                break;
            }
          },
        ),
      ),
    );
  }

  Future<void> _viewQuizDetails(String quizId, Map<String, dynamic> quizData) async {
    final questionsSnapshot = await FirebaseFirestore.instance
        .collection('quiz')
        .doc(quizId)
        .collection('questions')
        .get();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quizData['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text('Số câu hỏi: ${quizData['questionCount']}'),
              Text('Thời gian: ${quizData['duration']} phút'),
              const SizedBox(height: 20),
              const Text(
                'Danh sách câu hỏi:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: questionsSnapshot.docs.length,
                  itemBuilder: (context, index) {
                    final question = questionsSnapshot.docs[index].data();
                    final options = List<String>.from(question['options'] ?? []);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Câu ${index + 1}: ${question['question']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...options.asMap().entries.map((entry) {
                              final letter = String.fromCharCode(65 + entry.key);
                              final isCorrect = letter == question['correctAnswer'];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? Colors.green.shade50
                                      : Colors.grey.shade50,
                                  border: Border.all(
                                    color: isCorrect ? Colors.green : Colors.grey,
                                    width: isCorrect ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isCorrect ? Colors.green : Colors.grey,
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
                                    Expanded(child: Text(entry.value)),
                                    if (isCorrect)
                                      const Icon(Icons.check_circle, color: Colors.green),
                                  ],
                                ),
                              );
                            }).toList(),
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
      ),
    );
  }

  Future<void> _editQuiz(String quizId, Map<String, dynamic> quizData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditQuizPage(quizId: quizId, quizData: quizData),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đề thi đã được cập nhật'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleQuizStatus(String quizId, Map<String, dynamic> quizData) async {
    final currentStatus = quizData['status'] ?? 'available';
    final newStatus = currentStatus == 'available' ? 'archived' : 'available';

    try {
      await FirebaseFirestore.instance.collection('quiz').doc(quizId).update({
        'status': newStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'available' ? '✅ Đã mở đề thi' : '🔒 Đã đóng đề thi',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteQuiz(String quizId, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa đề thi "${data['title']}"?\n\n'
              'Hành động này sẽ xóa:\n'
              '• Đề thi\n'
              '• Tất cả câu hỏi\n'
              '• Không thể hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete all questions
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('quiz')
          .doc(quizId)
          .collection('questions')
          .get();

      for (var doc in questionsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the quiz
      await FirebaseFirestore.instance.collection('quiz').doc(quizId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa đề thi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi xóa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}