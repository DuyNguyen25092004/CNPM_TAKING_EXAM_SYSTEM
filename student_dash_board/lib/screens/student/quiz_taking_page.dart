// lib/screens/student/quiz_taking_page.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/anti_cheat_service.dart';
import '../../services/camera_proctoring_service.dart';
import '../../services/cross_platform_anti_cheat_service.dart';
import '../../services/firebase_service.dart';
import '../../services/web_anti_cheat_service.dart'
    if (dart.library.io) '../../services/web_anti_cheat_service_stub.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/platform_utils.dart';

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

class _QuizTakingPageState extends State<QuizTakingPage>
    with WidgetsBindingObserver {
  Map<String, String> answers = {};
  List<DateTime> answerTimestamps = [];
  List<int> questionTimes = [];
  DateTime? currentQuestionStartTime;
  // Add this variable to track last checked count:
  int _lastCheckedNoFaceCount = 0;
  bool isSubmitting = false;
  String? submissionId;

  late int remainingSeconds;
  late int totalSeconds;
  Timer? _timer;

  // Anti-cheat tracking
  final GlobalKey<AntiCheatMonitorState> _antiCheatKey = GlobalKey();
  int _warningCount = 0;
  int _appSwitchCount = 0;
  int _tabSwitchCount = 0;
  int _screenshotAttempts = 0;

  // Camera
  String? _cameraViewType;
  bool _isCameraActive = false;

  // Face detection tracking
  int _noFaceWarnings = 0;
  int _multipleFaceWarnings = 0;
  bool _isFaceDetected = true;
  bool _isFaceDetectionReady = false;
  DateTime? _lastFaceWarningTime;

  // Keyboard focus
  final FocusNode _focusNode = FocusNode();
  bool _keyboardListenerActive = false;

  @override
  void initState() {
    super.initState();
    totalSeconds = widget.duration * 60;
    remainingSeconds = totalSeconds;
    currentQuestionStartTime = DateTime.now();

    _startTimer();
    _setupPlatformSpecificFeatures();

    // Reset counters
    CrossPlatformAntiCheatService.resetCounters();

    // Get camera view type if already initialized
    if (kIsWeb) {
      final status = CameraProctoringService.getCameraStatus();
      if (status['isActive']) {
        _cameraViewType = status['viewType'];
        _isCameraActive = true;
        _isFaceDetectionReady = status['isFaceDetectionReady'] ?? false;

        // Re-setup face detection callbacks for this page
        _setupFaceDetectionCallbacksForQuiz();
      }

      // Setup page visibility listener to handle camera
      _setupPageVisibilityListener();
    }

    // Add lifecycle observer if supported
    if (PlatformUtils.supportsAppLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  void _setupFaceDetectionCallbacksForQuiz() {
    // Since camera is already initialized in dialog, we need to update the callbacks
    // This is a workaround because static callbacks in service are already set
    // We'll use a polling approach instead

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isCameraActive) {
        timer.cancel();
        return;
      }

      final stats = CameraProctoringService.getFaceDetectionStats();
      final currentNoFaceCount = stats['noFaceDetectedCount'] ?? 0;

      // Check if no face count increased
      if (currentNoFaceCount >= 3 &&
          currentNoFaceCount != _lastCheckedNoFaceCount) {
        _lastCheckedNoFaceCount = currentNoFaceCount;
        _handleFaceWarning(
          '⚠️ Không phát hiện khuôn mặt! Vui lòng quay lại camera.',
        );
      }
    });
  }

  void _setupPageVisibilityListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check camera status periodically
      Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted || !_isCameraActive) {
          timer.cancel();
          return;
        }

        _ensureCameraIsRunning();
      });
    });
  }

  void _setupFaceDetectionCallbacks() {
    // Note: Callbacks are already set during initializeCamera in CameraPermissionDialog
    // This method is for checking status after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!mounted || !_isCameraActive) {
          timer.cancel();
          return;
        }

        final status = CameraProctoringService.getCameraStatus();
        if (mounted &&
            status['isFaceDetectionReady'] != _isFaceDetectionReady) {
          setState(() {
            _isFaceDetectionReady = status['isFaceDetectionReady'] ?? false;
          });
        }
      });
    });
  }

  Future<void> _ensureCameraIsRunning() async {
    if (!kIsWeb || !_isCameraActive) return;

    final status = CameraProctoringService.getCameraStatus();

    // If camera claims to be active but video is not playing
    if (status['isActive'] == true && status['isPlaying'] == false) {
      print('⚠️ Camera is active but not playing, restarting...');

      final result = await CameraProctoringService.restartCamera();
      if (result['success'] && mounted) {
        setState(() {
          _cameraViewType = result['viewType'];
          _isCameraActive = true;
        });

        print('✅ Camera restarted successfully');
      }
    }
  }

  void _setupPlatformSpecificFeatures() {
    // Setup keyboard listener only on platforms that support it
    if (PlatformUtils.supportsHardwareKeyboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        HardwareKeyboard.instance.addHandler(_handleKeyEvent);
        _keyboardListenerActive = true;
      });
    }

    // Setup fullscreen only on mobile
    if (PlatformUtils.supportsFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    // Initialize Web Anti-Cheat if on web
    if (kIsWeb) {
      _initializeWebAntiCheat();
    }
  }

  void _initializeWebAntiCheat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        WebAntiCheatService.initialize(
          context: context,
          studentId: widget.studentId,
          quizId: widget.quizId,
          submissionId: submissionId,
          onTabSwitch: (count) {
            setState(() {
              _tabSwitchCount = count;
              _warningCount++;
            });

            if (_warningCount >= 3) {
              _showTooManyViolationsDialog();
            }

            // Check camera status after tab switch
            _checkCameraAfterTabSwitch();
          },
          onSuspiciousActivity: (type) {
            print('🚨 Suspicious activity: $type');
            setState(() {
              _warningCount++;

              if (type.contains('print') || type.contains('screenshot')) {
                _screenshotAttempts++;
              }
            });

            if (_warningCount >= 3) {
              _showTooManyViolationsDialog();
            }
          },
        );

        print('✅ Web Anti-Cheat initialized');
      }
    });
  }

  // Check and restart camera if needed after tab switch
  void _checkCameraAfterTabSwitch() async {
    if (!kIsWeb || !_isCameraActive) return;

    // Wait a bit for tab to fully activate
    await Future.delayed(const Duration(milliseconds: 1000));

    final status = CameraProctoringService.getCameraStatus();
    print('📹 Camera status after tab switch: $status');

    // If camera is not playing, try to restart
    if (status['isActive'] == true && status['isPlaying'] == false) {
      print('🔄 Camera not playing, attempting restart...');

      final result = await CameraProctoringService.restartCamera();
      if (result['success'] && mounted) {
        setState(() {
          _cameraViewType = result['viewType'];
          _isCameraActive = true;
        });
      }
    }
  }

  // Face detection handlers
  void _handleFaceWarning(String message) {
    // Debounce warnings (don't show too frequently)
    final now = DateTime.now();
    if (_lastFaceWarningTime != null) {
      final diff = now.difference(_lastFaceWarningTime!);
      if (diff.inSeconds < 5) {
        return; // Skip if last warning was less than 5 seconds ago
      }
    }

    _lastFaceWarningTime = now;

    // Update counters
    if (message.contains('Không phát hiện khuôn mặt')) {
      _noFaceWarnings++;
    } else if (message.contains('nhiều khuôn mặt')) {
      _multipleFaceWarnings++;
    }

    // INCREMENT SHARED WARNING COUNT
    setState(() {
      _warningCount++;
    });

    print('⚠️ Face warning: $message (Total warnings: $_warningCount)');

    // Log to Firestore
    if (submissionId != null) {
      CrossPlatformAntiCheatService.logSuspiciousActivity(
        submissionId: submissionId!,
        studentId: widget.studentId,
        quizId: widget.quizId,
        activityType: message.contains('Không phát hiện')
            ? 'no_face_detected'
            : 'multiple_faces_detected',
        details: message,
        severity: 'high',
      );
    }

    // Show warning snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // Force submit if too many warnings (unified threshold)
    if (_warningCount >= 3) {
      _showTooManyViolationsDialog();
    }
  }

  void _handleFaceDetected() {
    if (mounted) {
      setState(() {
        _isFaceDetected = true;
      });
    }
  }

  void _handleNoFaceDetected() {
    if (mounted) {
      setState(() {
        _isFaceDetected = false;
      });
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!PlatformUtils.supportsHardwareKeyboard) return false;
    return CrossPlatformAntiCheatService.handleKeyEvent(event, context);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _autoSubmitQuiz();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();

    if (_keyboardListenerActive && PlatformUtils.supportsHardwareKeyboard) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }

    if (PlatformUtils.supportsAppLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }

    if (PlatformUtils.supportsFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    // Dispose Web Anti-Cheat
    if (kIsWeb) {
      WebAntiCheatService.dispose();
    }

    // Stop camera when leaving quiz
    if (kIsWeb && _isCameraActive) {
      CameraProctoringService.stopCamera();
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!PlatformUtils.supportsAppLifecycle) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      CrossPlatformAntiCheatService.onVisibilityChanged(
        false,
        context,
        submissionId,
        widget.studentId,
        widget.quizId,
      );
    } else if (state == AppLifecycleState.resumed) {
      CrossPlatformAntiCheatService.onVisibilityChanged(
        true,
        context,
        submissionId,
        widget.studentId,
        widget.quizId,
      );
    }
  }

  double get _remainingPercentage => remainingSeconds / totalSeconds;

  void _handleAntiCheatActivity(
    int warnings,
    int appSwitches,
    int tabSwitches,
  ) {
    setState(() {
      _warningCount = warnings;
      _appSwitchCount = appSwitches;
      _tabSwitchCount = tabSwitches;
    });

    if (_warningCount >= 3) {
      _showTooManyViolationsDialog();
    }
  }

  void _showTooManyViolationsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text('Cảnh báo nghiêm trọng'),
          ],
        ),
        content: const Text(
          'Bạn đã vi phạm quá nhiều lần. Bài thi sẽ được nộp tự động.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _forceSubmitQuiz();
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  Future<void> _forceSubmitQuiz() async {
    final questionsSnapshot = await FirebaseService.getQuizQuestionsOnce(
      widget.quizId,
    );
    await _submitQuiz(questionsSnapshot.docs, forceSubmit: true);
  }

  void _onAnswerChanged(String questionId, String answer) {
    if (currentQuestionStartTime != null) {
      final timeSpent = DateTime.now()
          .difference(currentQuestionStartTime!)
          .inSeconds;
      questionTimes.add(timeSpent);
    }

    setState(() {
      answers[questionId] = answer;
      answerTimestamps.add(DateTime.now());
      currentQuestionStartTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await Helpers.showConfirmDialog(
          context,
          title: AppStrings.confirm,
          content: AppConstants.exitConfirmMessage,
          confirmText: AppStrings.exit,
          cancelText: AppStrings.stay,
        );
        return shouldPop ?? false;
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    Widget body = _buildBody();

    // Wrap with Focus only if keyboard supported
    if (PlatformUtils.supportsHardwareKeyboard && !kIsWeb) {
      body = Focus(focusNode: _focusNode, autofocus: true, child: body);
    }

    // Wrap with MouseRegion for all platforms
    body = MouseRegion(
      onHover: (event) {
        CrossPlatformAntiCheatService.trackMousePosition(event.position);
      },
      child: body,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizTitle),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Face detection indicator
          if (_isCameraActive && _isFaceDetectionReady)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isFaceDetected ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isFaceDetected
                            ? Icons.face
                            : Icons.face_retouching_off,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isFaceDetected ? 'OK' : 'NO FACE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Camera indicator
          if (_isCameraActive)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'REC',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Warning indicator
          if (_warningCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(_warningCount),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getSeverityIcon(_warningCount),
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_warningCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        Row(
          children: [
            // Main quiz content
            Expanded(
              flex: 7,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.getQuizQuestions(widget.quizId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('❌ Lỗi: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final questions = snapshot.data!.docs;

                  if (questions.isEmpty) {
                    return const Center(
                      child: Text('Bài thi này chưa có câu hỏi'),
                    );
                  }

                  return Column(
                    children: [
                      _buildTimerSection(questions.length),
                      const Divider(height: 1),
                      _buildProgressBar(questions.length),
                      _buildSecurityIndicator(),
                      if (_isCameraActive && _isFaceDetectionReady)
                        _buildFaceDetectionStatus(),
                      Expanded(child: _buildQuestionsList(questions)),
                      _buildSubmitButton(questions),
                    ],
                  );
                },
              ),
            ),

            // Camera preview sidebar (only on web)
            if (kIsWeb && _isCameraActive && _cameraViewType != null)
              Container(
                width: 300,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.red[50],
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Camera đang ghi hình',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (_isFaceDetectionReady)
                                  Text(
                                    '👤 Face Detection: ${_isFaceDetected ? "✅" : "⚠️"}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _isFaceDetected
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Debug button
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            onPressed: () async {
                              setState(() {
                                _isCameraActive = false;
                              });

                              final result =
                                  await CameraProctoringService.restartCamera();

                              if (result['success']) {
                                setState(() {
                                  _cameraViewType = result['viewType'];
                                  _isCameraActive = true;
                                });

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '✅ Camera đã khởi động lại',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '❌ Lỗi: ${result['error']}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            tooltip: 'Khởi động lại camera',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        child: HtmlElementView(viewType: _cameraViewType!),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey[100],
                      child: Column(
                        children: [
                          Text(
                            'Đảm bảo khuôn mặt luôn trong khung hình',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_noFaceWarnings > 0 ||
                              _multipleFaceWarnings > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Cảnh báo: No face: $_noFaceWarnings | Multiple: $_multipleFaceWarnings',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 4),
                          TextButton.icon(
                            onPressed: () {
                              final debugInfo =
                                  CameraProctoringService.getDebugInfo();
                              print(debugInfo);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(debugInfo),
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            label: Text(
                              'Kiểm tra trạng thái',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        // Anti-Cheat Monitor (only on supported platforms)
        if (PlatformUtils.supportsAppLifecycle && !kIsWeb)
          AntiCheatMonitor(
            key: _antiCheatKey,
            studentId: widget.studentId,
            quizId: widget.quizId,
            submissionId: submissionId,
            onActivityDetected: _handleAntiCheatActivity,
          ),
      ],
    );
  }

  Color _getSeverityColor(int warningCount) {
    if (warningCount >= 10) return Colors.red[900]!;
    if (warningCount >= 5) return Colors.red;
    if (warningCount >= 3) return Colors.orange;
    return Colors.yellow[700]!;
  }

  IconData _getSeverityIcon(int warningCount) {
    if (warningCount >= 10) return Icons.dangerous;
    if (warningCount >= 5) return Icons.warning_amber;
    return Icons.warning;
  }

  Widget _buildFaceDetectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _isFaceDetected ? Colors.green[50] : Colors.red[50],
      child: Row(
        children: [
          Icon(
            _isFaceDetected ? Icons.face : Icons.face_retouching_off,
            color: _isFaceDetected ? Colors.green[700] : Colors.red[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isFaceDetected
                  ? '✅ Khuôn mặt được phát hiện'
                  : '⚠️ KHÔNG PHÁT HIỆN KHUÔN MẶT! Vui lòng quay lại camera.',
              style: TextStyle(
                fontSize: 12,
                color: _isFaceDetected ? Colors.green[900] : Colors.red[900],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_noFaceWarnings > 0 || _multipleFaceWarnings > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Text(
                '⚠️ ${_noFaceWarnings + _multipleFaceWarnings}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityIndicator() {
    final features = PlatformUtils.availableAntiCheatFeatures;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[50],
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '🔒 ${PlatformUtils.platformName} | ${features.length} tính năng | Cảnh báo: $_warningCount',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isCameraActive) ...[
            const SizedBox(width: 8),
            Icon(Icons.videocam, color: Colors.red[700], size: 20),
          ],
          if (_isFaceDetectionReady) ...[
            const SizedBox(width: 8),
            Icon(Icons.face, color: Colors.green[700], size: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerSection(int totalQuestions) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    AppConstants.timerIcon,
                    color: Helpers.getTimerColor(_remainingPercentage),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Helpers.formatTime(remainingSeconds),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Helpers.getTimerColor(_remainingPercentage),
                    ),
                  ),
                ],
              ),
              Text(
                'Đã làm: ${answers.length}/$totalQuestions',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _remainingPercentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Helpers.getTimerColor(_remainingPercentage),
            ),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int totalQuestions) {
    return LinearProgressIndicator(
      value: answers.length / totalQuestions,
      backgroundColor: Colors.grey[300],
      valueColor: const AlwaysStoppedAnimation<Color>(
        AppConstants.primaryColor,
      ),
      minHeight: 4,
    );
  }

  Widget _buildQuestionsList(List<QueryDocumentSnapshot> questions) {
    return ListView.builder(
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: answers.containsKey(question.id)
                            ? Colors.green[100]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Câu ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: answers.containsKey(question.id)
                              ? Colors.green[900]
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data['question'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...options.asMap().entries.map((entry) {
                  final optionIndex = entry.key;
                  final option = entry.value;
                  final optionLabel = Helpers.getOptionLabel(optionIndex);

                  return RadioListTile<String>(
                    title: Text('$optionLabel. $option'),
                    value: optionLabel,
                    groupValue: answers[question.id],
                    onChanged: (value) {
                      _onAnswerChanged(question.id, value!);
                    },
                    activeColor: AppConstants.primaryColor,
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton(List<QueryDocumentSnapshot> questions) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : () => _submitQuiz(questions),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: AppConstants.successColor,
          foregroundColor: Colors.white,
        ),
        child: isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(AppStrings.submit, style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Future<void> _autoSubmitQuiz() async {
    if (isSubmitting) return;

    Helpers.showSnackBar(
      context,
      AppConstants.timeUpMessage,
      backgroundColor: AppConstants.warningColor,
    );

    await Future.delayed(const Duration(seconds: 1));

    final questionsSnapshot = await FirebaseService.getQuizQuestionsOnce(
      widget.quizId,
    );
    await _submitQuiz(questionsSnapshot.docs, autoSubmit: true);
  }

  Future<void> _submitQuiz(
    List<QueryDocumentSnapshot> questions, {
    bool autoSubmit = false,
    bool forceSubmit = false,
  }) async {
    if (!autoSubmit && !forceSubmit && answers.length != questions.length) {
      Helpers.showSnackBar(context, AppConstants.answerAllQuestionsMessage);
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    _timer?.cancel();

    int score = 0;
    for (var question in questions) {
      final data = question.data() as Map<String, dynamic>;
      if (answers[question.id] == data['correctAnswer']) {
        score++;
      }
    }

    final docRef = await FirebaseService.submitQuiz(
      studentId: widget.studentId,
      quizId: widget.quizId,
      quizTitle: widget.quizTitle,
      score: score,
      totalQuestions: questions.length,
      answers: answers,
      timeSpent: widget.duration * 60 - remainingSeconds,
    );

    // Get web statistics if on web
    if (kIsWeb) {
      final webStats = WebAntiCheatService.getStatistics();
      _tabSwitchCount = webStats['tabSwitchCount'] ?? 0;
      _screenshotAttempts = webStats['screenshotAttempts'] ?? 0;
      print('📊 Web stats: $webStats');
    }

    // Generate cross-platform anti-cheat report
    await CrossPlatformAntiCheatService.generateAntiCheatReport(
      submissionId: docRef.id,
      studentId: widget.studentId,
      quizId: widget.quizId,
      answers: answers,
      answerTimestamps: answerTimestamps,
      totalTimeSpent: widget.duration * 60 - remainingSeconds,
      quizDuration: widget.duration,
      appSwitchCount: _appSwitchCount,
      tabSwitchCount: _tabSwitchCount,
      warningCount: _warningCount,
      questionTimes: questionTimes,
    );

    if (!mounted) return;

    Navigator.pop(context);
    _showResultDialog(score, questions.length, autoSubmit, forceSubmit);
  }

  void _showResultDialog(
    int score,
    int total,
    bool autoSubmit,
    bool forceSubmit,
  ) {
    final percentage = score / total;
    String title = AppStrings.completed;

    if (autoSubmit) {
      title = '⏰ Hết giờ!';
    } else if (forceSubmit) {
      title = '⚠️ Nộp bài do vi phạm';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              percentage >= AppConstants.excellentScoreThreshold
                  ? AppConstants.trophyIcon
                  : AppConstants.thumbUpIcon,
              size: 60,
              color: percentage >= AppConstants.excellentScoreThreshold
                  ? AppConstants.goldColor
                  : AppConstants.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Điểm của bạn: $score/$total',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${Helpers.getPercentageString(score, total)}%',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Platform: ${PlatformUtils.platformName}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (_warningCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    const Text(
                      '⚠️ Thông báo bảo mật',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Tổng cảnh báo: $_warningCount'),
                    if (kIsWeb && _tabSwitchCount > 0) ...[
                      const SizedBox(height: 4),
                      Text('📱 Chuyển tab: $_tabSwitchCount lần'),
                    ],
                    if (kIsWeb && _screenshotAttempts > 0) ...[
                      const SizedBox(height: 4),
                      Text('📸 Chụp màn hình: $_screenshotAttempts lần'),
                    ],
                    if (_noFaceWarnings > 0) ...[
                      const SizedBox(height: 4),
                      Text('👤 Không có mặt: $_noFaceWarnings lần'),
                    ],
                    if (_multipleFaceWarnings > 0) ...[
                      const SizedBox(height: 4),
                      Text('👥 Nhiều người: $_multipleFaceWarnings lần'),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Bài thi đã được ghi lại để xem xét',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }
}
