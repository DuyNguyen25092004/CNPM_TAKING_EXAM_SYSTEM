// lib/screens/student/quiz_taking_page.dart
import 'dart:async';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuizTakingPage extends StatefulWidget {
  final String quizId;
  final String classId;
  final String quizTitle;
  final int duration;
  final String studentId;

  const QuizTakingPage({
    Key? key,
    required this.quizId,
    required this.classId,
    required this.quizTitle,
    required this.duration,
    required this.studentId,
  }) : super(key: key);

  @override
  State<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<QuizTakingPage>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();

  // State variables
  int _currentIndex = 0;
  int _secondsRemaining = 0;
  Timer? _timer;
  bool _isSubmitting = false;
  bool _isLoading = true;

  // Data
  List<QueryDocumentSnapshot> _questions = [];
  final Map<String, String> _answers = {};

  // ============================================
  // CHEATING DETECTION VARIABLES
  // ============================================
  int _suspiciousActionCount = 0;
  static const int _maxSuspiciousActions = 5;
  bool _hasShownWarning = false;
  DateTime? _lastFocusLossTime;
  bool _isInitialFullscreenEntry = true;
  bool _isCurrentlyAway = false; // Mới: theo dõi trạng thái đã rời đi
  // ============================================
  // FULLSCREEN & WINDOW MONITORING VARIABLES
  // ============================================
  bool _isFullscreen = false;
  bool _isEnteringFullscreen = false;
  Size? _initialWindowSize;
  Timer? _windowMonitorTimer;
  html.EventListener? _fullscreenChangeListener;
  html.EventListener? _windowResizeListener;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.duration * 60;
    _loadQuestions();
    _startTimer();

    // Register lifecycle observer for focus detection
    WidgetsBinding.instance.addObserver(this);

    // Initialize fullscreen enforcement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enforceFullscreen();
      _startWindowMonitoring();
    });

    print('🔒 Anti-cheating system activated');
    print('   Max violations allowed: $_maxSuspiciousActions');
    print('   Fullscreen enforcement: ENABLED');
    print('   Window resize detection: ENABLED');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _windowMonitorTimer?.cancel();
    _pageController.dispose();

    // Cleanup fullscreen listeners
    _cleanupFullscreenListeners();

    // Exit fullscreen if still active
    if (_isFullscreen) {
      html.document.exitFullscreen();
    }

    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ============================================
  // FULLSCREEN ENFORCEMENT
  // ============================================

  void _enforceFullscreen() {
    try {
      // Set flag TRƯỚC KHI request fullscreen
      _isEnteringFullscreen = true;

      // Request fullscreen
      html.document.documentElement?.requestFullscreen();

      // Setup fullscreen change listener
      _fullscreenChangeListener = (html.Event event) {
        _onFullscreenChange();
      };

      html.document.addEventListener(
        'fullscreenchange',
        _fullscreenChangeListener!,
      );
      html.document.addEventListener(
        'webkitfullscreenchange',
        _fullscreenChangeListener!,
      );
      html.document.addEventListener(
        'mozfullscreenchange',
        _fullscreenChangeListener!,
      );
      html.document.addEventListener(
        'msfullscreenchange',
        _fullscreenChangeListener!,
      );

      setState(() {
        _isFullscreen = true;
      });

      print('✅ Fullscreen mode activated');
    } catch (e) {
      _isEnteringFullscreen = false; // Reset flag nếu có lỗi
      print('⚠️ Fullscreen enforcement error: $e');
    }
  }

  void _showReenterFullscreenDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.fullscreen, color: Colors.orange.shade600, size: 32),
                const SizedBox(width: 12),
                const Text('Vào lại chế độ fullscreen'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vi phạm ${_suspiciousActionCount}/$_maxSuspiciousActions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bạn phải làm bài trong chế độ fullscreen.',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn nút bên dưới để tiếp tục làm bài.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);

                  // Set flag TRƯỚC KHI request fullscreen
                  _isEnteringFullscreen = true;

                  try {
                    html.document.documentElement?.requestFullscreen();
                    print('✅ Re-entering fullscreen via user action');
                  } catch (e) {
                    _isEnteringFullscreen = false; // Reset nếu lỗi
                    print('⚠️ Failed to re-enter fullscreen: $e');
                  }
                },
                icon: const Icon(Icons.fullscreen),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: const Text(
                  'Vào fullscreen',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onFullscreenChange() {
    final isCurrentlyFullscreen = html.document.fullscreenElement != null;

    if (isCurrentlyFullscreen) {
      // ✅ VÀO FULLSCREEN THÀNH CÔNG
      if (mounted) {
        setState(() {
          _isFullscreen = true;
        });
      }

      // Reset cả 2 flags
      _isEnteringFullscreen = false;
      _isInitialFullscreenEntry = false;

      // CẬP NHẬT initial window size SAU KHI vào fullscreen
      _initialWindowSize = Size(
        html.window.innerWidth!.toDouble(),
        html.window.innerHeight!.toDouble(),
      );

      print('✅ Entered fullscreen successfully');
      print(
        '📐 Updated window size: ${_initialWindowSize!.width}x${_initialWindowSize!.height}',
      );
    } else if (!isCurrentlyFullscreen && !_isSubmitting && !_isLoading) {
      // ❌ THOÁT FULLSCREEN

      // CHỈ IGNORE nếu đang entering VÀ _isFullscreen vẫn là false
      // (tức là chưa bao giờ vào fullscreen thành công)
      if (_isEnteringFullscreen && !_isFullscreen) {
        print('⏭️ Ignoring fullscreen exit during initial entry process');
        return;
      }

      // Reset flag để tránh conflict
      _isEnteringFullscreen = false;

      // User THỰC SỰ thoát fullscreen
      print('⚠️ User exited fullscreen mode');

      if (mounted) {
        setState(() {
          _isFullscreen = false;
        });
      }

      // Handle suspicious action - CHỈ TÍNH 1 LẦN
      _handleSuspiciousAction('Exited fullscreen mode');

      // Show dialog to re-enter fullscreen
      if (mounted && _suspiciousActionCount < _maxSuspiciousActions) {
        _showReenterFullscreenDialog();
      }
    }
  }

  void _cleanupFullscreenListeners() {
    if (_fullscreenChangeListener != null) {
      html.document.removeEventListener(
        'fullscreenchange',
        _fullscreenChangeListener!,
      );
      html.document.removeEventListener(
        'webkitfullscreenchange',
        _fullscreenChangeListener!,
      );
      html.document.removeEventListener(
        'mozfullscreenchange',
        _fullscreenChangeListener!,
      );
      html.document.removeEventListener(
        'msfullscreenchange',
        _fullscreenChangeListener!,
      );
    }
  }

  // ============================================
  // WINDOW RESIZE MONITORING
  // ============================================

  void _startWindowMonitoring() {
    // Capture initial window size
    _initialWindowSize = Size(
      html.window.innerWidth!.toDouble(),
      html.window.innerHeight!.toDouble(),
    );

    print(
      '📐 Initial window size: ${_initialWindowSize!.width}x${_initialWindowSize!.height}',
    );

    // Setup resize listener
    _windowResizeListener = (html.Event event) {
      _onWindowResize();
    };

    html.window.addEventListener('resize', _windowResizeListener!);

    // Additional periodic check (backup mechanism)
    _windowMonitorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isSubmitting && !_isLoading) {
        _checkWindowSize();
      }
    });
  }

  void _onWindowResize() {
    if (_isSubmitting || _isLoading) return;

    // Ignore nếu đang entering fullscreen hoặc lần đầu init
    if (_isEnteringFullscreen || _isInitialFullscreenEntry) {
      print('⏭️ Ignoring window resize event during fullscreen entry/init');
      return;
    }

    _checkWindowSize();
  }

  void _checkWindowSize() {
    if (_initialWindowSize == null) return;

    // Ignore nếu đang entering fullscreen hoặc lần đầu init
    if (_isEnteringFullscreen || _isInitialFullscreenEntry) {
      print('⏭️ Ignoring window resize during fullscreen entry/init');
      return;
    }

    // 🔥 NEW: Check actual fullscreen state from browser
    final isCurrentlyFullscreen = html.document.fullscreenElement != null;

    // Ignore window resize if not in fullscreen (means user already exited)
    if (!isCurrentlyFullscreen) {
      print('⏭️ Ignoring window resize - not in fullscreen mode');
      return;
    }

    final currentSize = Size(
      html.window.innerWidth!.toDouble(),
      html.window.innerHeight!.toDouble(),
    );

    // Check if size changed significantly (more than 10px in either dimension)
    final widthDiff = (currentSize.width - _initialWindowSize!.width).abs();
    final heightDiff = (currentSize.height - _initialWindowSize!.height).abs();

    if (widthDiff > 10 || heightDiff > 10) {
      print('⚠️ Window resize detected');
      print(
        '   Initial: ${_initialWindowSize!.width}x${_initialWindowSize!.height}',
      );
      print('   Current: ${currentSize.width}x${currentSize.height}');

      _handleSuspiciousAction('Window resize detected');

      // Update initial size to prevent repeated triggers
      _initialWindowSize = currentSize;
    }
  }

  // ============================================
  // CHEATING DETECTION: APP LIFECYCLE HANDLER
  // ============================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_isSubmitting || _isLoading) return;

    print('📱 App lifecycle changed: $state');

    if ((state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden)) {
      if (_isEnteringFullscreen || _isInitialFullscreenEntry) {
        print(
          '⏭️ Ignoring lifecycle PAUSED/INACTIVE during fullscreen entry/init',
        );
        return;
      }

      // ⚠️ CHỈ GHI NHẬN VI PHẠM NẾU TRƯỚC ĐÓ CHƯA RỜI ĐI
      if (!_isCurrentlyAway) {
        _isCurrentlyAway = true; // Đánh dấu là đã rời đi
        _handleSuspiciousAction('Tab/Window switch detected');
      } else {
        print('⏭️ Ignoring redundant PAUSED/INACTIVE event');
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isEnteringFullscreen || _isInitialFullscreenEntry) {
        print('⏭️ Ignoring lifecycle RESUMED during fullscreen entry/init');
        return;
      }

      print('✅ App resumed - user returned');

      // RESET cờ khi người dùng quay lại
      _isCurrentlyAway = false;

      if (!_isFullscreen) {
        _enforceFullscreen();
      }
    }
  }

  // ============================================
  // CHEATING DETECTION: HANDLE SUSPICIOUS ACTION
  // ============================================
  // ============================================
  // CHEATING DETECTION: HANDLE SUSPICIOUS ACTION
  // ============================================
  void _handleSuspiciousAction(String reason) {
    final now = DateTime.now();

    // Prevent multiple triggers within 2 seconds

    if (_lastFocusLossTime != null &&
        now.difference(_lastFocusLossTime!).inSeconds < 2) {
      print('⏭️ Skipping duplicate detection within 2 seconds');

      return;
    }

    _lastFocusLossTime = now; // Giữ lại để lưu trữ thời điểm xảy ra vi phạm

    setState(() {
      _suspiciousActionCount++;
    });

    print('⚠️ SUSPICIOUS ACTION #$_suspiciousActionCount: $reason');
    print(
      '   Remaining warnings: ${_maxSuspiciousActions - _suspiciousActionCount}',
    );

    if (_suspiciousActionCount >= _maxSuspiciousActions) {
      // Auto-submit after exceeding limit
      print('🚨 MAX VIOLATIONS REACHED - AUTO SUBMITTING');
      _autoSubmitForCheating();
    } else if (_suspiciousActionCount == _maxSuspiciousActions - 1 &&
        !_hasShownWarning) {
      // Show final warning
      _showFinalWarning();
    } else {
      // Show violation notification
      _showViolationNotification();
    }

    // FORCE REBUILD UI sau khi xử lý xong để cập nhật counter trên header
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================
  // SHOW VIOLATION NOTIFICATION
  // ============================================
  void _showViolationNotification() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cảnh báo vi phạm!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Lần ${_suspiciousActionCount}/$_maxSuspiciousActions - Không được chuyển tab/cửa sổ hoặc thoát fullscreen',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================
  // SHOW FINAL WARNING DIALOG
  // ============================================
  void _showFinalWarning() {
    if (!mounted || _hasShownWarning) return;

    _hasShownWarning = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        // <-- THÊM StatefulBuilder
        builder: (context, setDialogState) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cảnh báo cuối cùng!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vi phạm ${_suspiciousActionCount}/$_maxSuspiciousActions', // <-- Sẽ tự động update
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '⚠️ Bạn đã vi phạm quá nhiều lần!',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Text(
                  'Các hành vi bị cấm:\n'
                  '• Chuyển tab/cửa sổ\n'
                  '• Thoát chế độ fullscreen\n'
                  '• Thay đổi kích thước cửa sổ\n\n'
                  'Nếu vi phạm thêm 1 lần nữa, bài thi sẽ tự động nộp ngay lập tức.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Hãy tập trung làm bài trong chế độ fullscreen',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tôi hiểu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // AUTO SUBMIT FOR CHEATING
  // ============================================
  Future<void> _autoSubmitForCheating() async {
    if (_isSubmitting) return;

    print('🚨 AUTO-SUBMITTING DUE TO CHEATING');

    // Show immediate notification
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '🚨 Bài thi tự động nộp do vi phạm quá nhiều lần!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Wait a moment for the message to be visible
    await Future.delayed(const Duration(milliseconds: 500));

    // Submit with cheating flag
    await _submitQuizWithCheatingFlag();
  }

  // ============================================
  // SUBMIT QUIZ WITH CHEATING FLAG
  // ============================================
  Future<void> _submitQuizWithCheatingFlag() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      int score = 0;

      // Calculate score
      for (var doc in _questions) {
        final data = doc.data() as Map<String, dynamic>;
        final qId = doc.id;
        final correctAnswer = data['correctAnswer'];
        final studentAnswer = _answers[qId];

        if (studentAnswer == correctAnswer) {
          score++;
        }
      }

      // Submit to Firestore with cheating metadata
      await FirebaseFirestore.instance.collection('submissions').add({
        'studentId': widget.studentId,
        'quizId': widget.quizId,
        'classId': widget.classId,
        'quizTitle': widget.quizTitle,
        'answers': _answers,
        'score': score,
        'totalQuestions': _questions.length,
        'timestamp': FieldValue.serverTimestamp(),
        'timeSpent': (widget.duration * 60) - _secondsRemaining,
        // Cheating detection metadata
        'cheatingDetected': true,
        'suspiciousActionCount': _suspiciousActionCount,
        'autoSubmitted': true,
        'submissionReason': 'Auto-submitted due to excessive violations',
      });

      print('✅ Quiz submitted with cheating flag');
      print('   Score: $score/${_questions.length}');
      print('   Violations: $_suspiciousActionCount');

      if (mounted) {
        Navigator.pop(context);

        // Show detailed result dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade600,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Text('Bài thi đã nộp'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.block, color: Colors.red.shade600, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Bài thi đã tự động nộp',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Do vi phạm quy định $_suspiciousActionCount lần',
                          style: TextStyle(color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Điểm số:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '$score/${_questions.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Return to quiz list
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      print('❌ Error submitting quiz: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi nộp bài: $e')));
      }
    }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải câu hỏi: $e')));
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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isTimeRunningOut = _secondsRemaining < 300;

    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bạn không thể thoát khi đang làm bài! Hãy nộp bài trước.',
            ),
          ),
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
                // Header Custom with violation counter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isTimeRunningOut
                              ? Colors.red.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isTimeRunningOut
                                ? Colors.red.shade200
                                : Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: isTimeRunningOut
                                  ? Colors.red
                                  : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(_secondsRemaining),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isTimeRunningOut
                                    ? Colors.red
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Violation counter (only show if violations exist)
                      if (_suspiciousActionCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _suspiciousActionCount >=
                                    _maxSuspiciousActions - 1
                                ? Colors.red.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  _suspiciousActionCount >=
                                      _maxSuspiciousActions - 1
                                  ? Colors.red.shade300
                                  : Colors.orange.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color:
                                    _suspiciousActionCount >=
                                        _maxSuspiciousActions - 1
                                    ? Colors.red.shade700
                                    : Colors.orange.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_suspiciousActionCount/$_maxSuspiciousActions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color:
                                      _suspiciousActionCount >=
                                          _maxSuspiciousActions - 1
                                      ? Colors.red.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Spacer(),

                      Builder(
                        builder: (context) => InkWell(
                          onTap: () => Scaffold.of(context).openEndDrawer(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.grid_view_rounded,
                                  size: 20,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_answers.length}/${_questions.length} câu',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

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

                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.blue.shade600,
                          ),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            return _buildQuestionPage(index);
                          },
                        ),
                ),

                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),

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
                          icon: Icon(
                            _currentIndex < _questions.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.check_circle_outline,
                          ),
                          label: Text(
                            _currentIndex < _questions.length - 1
                                ? 'Câu sau'
                                : 'Hoàn thành',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _currentIndex < _questions.length - 1
                                ? Colors.blue.shade50
                                : Colors.green.shade600,
                            foregroundColor:
                                _currentIndex < _questions.length - 1
                                ? Colors.blue.shade700
                                : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                    color: isSelected
                        ? Colors.blue.shade400
                        : Colors.grey.shade200,
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
                        color: isSelected
                            ? Colors.blue.shade600
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
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
                          color: isSelected
                              ? Colors.blue.shade900
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.blue.shade600,
                      ),
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
                    const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
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
                    _buildLegendItem(
                      Colors.orange.shade400,
                      'Đang chọn',
                      isBorder: true,
                    ),
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
                      boxShadow: isAnswered
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isAnswered
                              ? Colors.white
                              : Colors.grey.shade700,
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
                    child: const Text(
                      'Nộp bài thi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
          'Bạn có chắc chắn muốn nộp bài không?',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
            ),
            child: const Text(
              'Nộp ngay',
              style: TextStyle(color: Colors.white),
            ),
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
        'studentId': widget.studentId,
        'quizId': widget.quizId,
        'classId': widget.classId,
        'quizTitle': widget.quizTitle,
        'answers': _answers,
        'score': score,
        'totalQuestions': _questions.length,
        'timestamp': FieldValue.serverTimestamp(),
        'timeSpent': (widget.duration * 60) - _secondsRemaining,
        'cheatingDetected': false,
        'suspiciousActionCount': _suspiciousActionCount,
        'autoSubmitted': false,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nộp bài thành công! Điểm số: $score/${_questions.length}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi nộp bài: $e')));
      }
    }
  }
}
