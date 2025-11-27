// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const StudentPanel(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StudentPanel extends StatefulWidget {
  const StudentPanel({Key? key}) : super(key: key);

  @override
  State<StudentPanel> createState() => _StudentPanelState();
}

class _StudentPanelState extends State<StudentPanel> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const QuizListPage(),
    const SubmitQuizPage(),
    const HistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎓 Học sinh Panel'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz),
            label: 'Làm bài thi',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload),
            label: 'Nộp bài',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
        ],
      ),
    );
  }
}

// 1. DASHBOARD PAGE
class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final quizzes = snapshot.data!.docs;
        final availableQuizzes = quizzes.where((q) => q['status'] == 'available').length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.quiz, size: 60, color: Colors.blue),
                    const SizedBox(height: 10),
                    Text(
                      'Bài thi khả dụng',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$availableQuizzes',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Thông tin nổi bật',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('submissions')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Đang tải...'),
                    ),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Chưa có bài nộp nào'),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text('Bài thi: ${data['quizTitle'] ?? 'N/A'}'),
                        subtitle: Text('Điểm: ${data['score'] ?? 0}/${data['totalQuestions'] ?? 0}'),
                        trailing: Text(
                          _formatTimestamp(data['timestamp']),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    final dt = (timestamp as Timestamp).toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// 2. QUIZ LIST PAGE (Làm bài thi)
class QuizListPage extends StatelessWidget {
  const QuizListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quiz')
          .where('status', isEqualTo: 'available')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('❌ Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        print('📊 Số quiz tìm thấy: ${snapshot.data!.docs.length}');

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Không có bài thi nào khả dụng'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final quiz = snapshot.data!.docs[index];
            final data = quiz.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  data['title'] ?? 'Untitled Quiz',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Số câu hỏi: ${data['questionCount'] ?? 0}'),
                    Text('Thời gian: ${data['duration'] ?? 0} phút'),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizTakingPage(
                          quizId: quiz.id,
                          quizTitle: data['title'] ?? 'Quiz',
                        ),
                      ),
                    );
                  },
                  child: const Text('Bắt đầu'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// QUIZ TAKING PAGE
class QuizTakingPage extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const QuizTakingPage({
    Key? key,
    required this.quizId,
    required this.quizTitle,
  }) : super(key: key);

  @override
  State<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<QuizTakingPage> {
  Map<String, String> answers = {};
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizTitle),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quiz')
            .doc(widget.quizId)
            .collection('questions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('❌ Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data!.docs;

          print('📝 Số câu hỏi tìm thấy: ${questions.length}');

          if (questions.isEmpty) {
            return const Center(child: Text('Bài thi này chưa có câu hỏi'));
          }

          return Column(
            children: [
              LinearProgressIndicator(
                value: answers.length / questions.length,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Đã hoàn thành: ${answers.length}/${questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
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
                              final optionLabel = String.fromCharCode(65 + optionIndex);

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
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () => _submitQuiz(questions),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Nộp bài', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitQuiz(List<QueryDocumentSnapshot> questions) async {
    if (answers.length != questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng trả lời tất cả câu hỏi!')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    int score = 0;
    for (var question in questions) {
      final data = question.data() as Map<String, dynamic>;
      if (answers[question.id] == data['correctAnswer']) {
        score++;
      }
    }

    await FirebaseFirestore.instance.collection('submissions').add({
      'quizId': widget.quizId,
      'quizTitle': widget.quizTitle,
      'score': score,
      'totalQuestions': questions.length,
      'answers': answers,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết quả'),
        content: Text('Điểm của bạn: $score/${questions.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// 3. SUBMIT QUIZ PAGE (Nộp bài & chấm điểm)
class SubmitQuizPage extends StatelessWidget {
  const SubmitQuizPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Nộp bài tự động',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bài thi của bạn sẽ được nộp và chấm điểm tự động khi bạn hoàn thành tất cả câu hỏi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to quiz list
                final panel = context.findAncestorStateOfType<_StudentPanelState>();
                panel?.setState(() {
                  panel._selectedIndex = 1;
                });
              },
              child: const Text('Đi tới làm bài thi'),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. HISTORY PAGE (Lịch sử thi)
class HistoryPage extends StatelessWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('submissions')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Chưa có bài thi nào'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final submission = snapshot.data!.docs[index];
            final data = submission.data() as Map<String, dynamic>;

            final score = data['score'] ?? 0;
            final total = data['totalQuestions'] ?? 1;
            final percentage = (score / total * 100).toStringAsFixed(0);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getScoreColor(score / total),
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(data['quizTitle'] ?? 'N/A'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Điểm số: $score/$total'),
                    Text(_formatTimestamp(data['timestamp'])),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultDetailPage(
                          submissionId: submission.id,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    final dt = (timestamp as Timestamp).toDate();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}';
  }
}

// RESULT DETAIL PAGE
class ResultDetailPage extends StatelessWidget {
  final String submissionId;

  const ResultDetailPage({Key? key, required this.submissionId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết kết quả'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('submissions')
            .doc(submissionId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        data['quizTitle'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${data['score']}/${data['totalQuestions']}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '${((data['score'] / data['totalQuestions']) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Câu trả lời của bạn',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...((data['answers'] as Map<String, dynamic>).entries.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text('Câu hỏi ${entry.key}'),
                    subtitle: Text('Đáp án: ${entry.value}'),
                  ),
                );
              }).toList()),
            ],
          );
        },
      ),
    );
  }
}