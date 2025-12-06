// lib/screens/teacher/class_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class ClassDetailPage extends StatefulWidget {
  final String classId;
  final String className;

  const ClassDetailPage({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _studentEmailController = TextEditingController();
  final _studentNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentEmailController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  // Extract 9 digits from email (before @)
  String _extractStudentId(String email) {
    final parts = email.split('@');
    if (parts.isEmpty) return '';

    // Get the part before @
    final username = parts[0];

    // Extract first 9 digits from username
    final digits = username.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length >= 9) {
      return digits.substring(0, 9);
    }

    return digits;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Học sinh'),
            Tab(icon: Icon(Icons.quiz), text: 'Bài thi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentsTab(),
          _buildQuizzesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddStudentDialog();
          } else {
            _showAssignQuizDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Thêm học sinh' : 'Gán bài thi'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildStudentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có học sinh nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn nút "+" để thêm học sinh',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final students = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final data = student.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    data['name']?.substring(0, 1).toUpperCase() ?? 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  data['name'] ?? 'Không có tên',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${data['studentId']}'),
                    Text('Email: ${data['email']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa'),
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
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditStudentDialog(student.id, data);
                    } else if (value == 'delete') {
                      _deleteStudent(student.id, data);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuizzesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có bài thi nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn nút "+" để gán bài thi cho lớp',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final quizzes = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            final data = quiz.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    '${data['questionCount'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  data['title'] ?? 'Bài thi',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Số câu hỏi: ${data['questionCount'] ?? 0}'),
                    Text('Thời gian: ${data['duration'] ?? 0} phút'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeQuizFromClass(quiz.id, data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddStudentDialog() {
    _studentEmailController.clear();
    _studentNameController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thêm học sinh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _studentEmailController,
              decoration: const InputDecoration(
                labelText: 'Email học sinh',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                hintText: 'VD: 123456789@student.edu.vn',
                helperText: '9 chữ số đầu email sẽ là mã học sinh',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _studentNameController,
              decoration: const InputDecoration(
                labelText: 'Tên học sinh',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                hintText: 'VD: Nguyễn Văn A',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => _addStudent(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(String studentDocId, Map<String, dynamic> data) {
    _studentEmailController.text = data['email'] ?? '';
    _studentNameController.text = data['name'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chỉnh sửa học sinh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _studentEmailController,
              decoration: const InputDecoration(
                labelText: 'Email học sinh',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              enabled: false, // Cannot change email
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _studentNameController,
              decoration: const InputDecoration(
                labelText: 'Tên học sinh',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => _updateStudent(studentDocId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showAssignQuizDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chọn bài thi',
                      style: TextStyle(
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
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('quiz')
                      .where('status', isEqualTo: 'available')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('Không có bài thi nào khả dụng'),
                      );
                    }

                    final quizzes = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: quizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = quizzes[index];
                        final data = quiz.data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                '${data['questionCount'] ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              data['title'] ?? 'Bài thi',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Số câu: ${data['questionCount'] ?? 0}'),
                                Text('Thời gian: ${data['duration'] ?? 0} phút'),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _assignQuizToClass(quiz.id, data),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Gán'),
                            ),
                          ),
                        );
                      },
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

  Future<void> _addStudent() async {
    final email = _studentEmailController.text.trim();
    final name = _studentNameController.text.trim();

    if (email.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập đầy đủ thông tin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate email
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Email không hợp lệ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Extract student ID from email
    final studentId = _extractStudentId(email);

    if (studentId.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Email phải chứa ít nhất 9 chữ số'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Check if student already exists in this class
      final existingStudent = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(studentId) // Use studentId as document ID
          .get();

      if (existingStudent.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Học sinh đã tồn tại trong lớp'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Add student with studentId as document ID
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(studentId) // Use studentId as document ID
          .set({
        'studentId': studentId,
        'email': email,
        'name': name,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Update student count
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final currentCount = (classDoc.data()?['studentCount'] ?? 0) as int;

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({
        'studentCount': currentCount + 1,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Thêm học sinh thành công! ID: $studentId'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateStudent(String studentDocId) async {
    if (_studentNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập tên học sinh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(studentDocId)
          .update({
        'name': _studentNameController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cập nhật học sinh thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteStudent(
      String studentDocId, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa học sinh "${data['name']}"?'),
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
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(studentDocId)
          .delete();

      // Update student count
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final currentCount = (classDoc.data()?['studentCount'] ?? 1) as int;

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({
        'studentCount': currentCount > 0 ? currentCount - 1 : 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa học sinh'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _assignQuizToClass(
      String quizId, Map<String, dynamic> quizData) async {
    try {
      // Check if quiz already assigned
      final existingQuiz = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .doc(quizId)
          .get();

      if (existingQuiz.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Bài thi đã được gán cho lớp này'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .doc(quizId)
          .set({
        'title': quizData['title'],
        'questionCount': quizData['questionCount'],
        'duration': quizData['duration'],
        'assignedAt': FieldValue.serverTimestamp(),
      });

      // Update quiz count
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final currentCount = (classDoc.data()?['quizCount'] ?? 0) as int;

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({
        'quizCount': currentCount + 1,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Gán bài thi thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeQuizFromClass(
      String quizId, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận gỡ bỏ'),
        content: Text('Bạn có chắc muốn gỡ bài thi "${data['title']}" khỏi lớp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Gỡ bỏ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .doc(quizId)
          .delete();

      // Update quiz count
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final currentCount = (classDoc.data()?['quizCount'] ?? 1) as int;

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({
        'quizCount': currentCount > 0 ? currentCount - 1 : 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã gỡ bài thi khỏi lớp'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}