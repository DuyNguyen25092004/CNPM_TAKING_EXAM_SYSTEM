// lib/services/anti_cheat_service.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AntiCheatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track suspicious activities
  static Future<void> logSuspiciousActivity({
    required String submissionId,
    required String studentId,
    required String quizId,
    required String activityType,
    String? details,
  }) async {
    await _firestore.collection('suspicious_activities').add({
      'submissionId': submissionId,
      'studentId': studentId,
      'quizId': quizId,
      'activityType': activityType,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Update submission with anti-cheat data
  static Future<void> updateSubmissionAntiCheat({
    required String submissionId,
    required int appSwitchCount,
    required int tabSwitchCount,
    required bool wasFullscreen,
    required int warningCount,
  }) async {
    await _firestore.collection('submissions').doc(submissionId).update({
      'antiCheat': {
        'appSwitchCount': appSwitchCount,
        'tabSwitchCount': tabSwitchCount,
        'wasFullscreen': wasFullscreen,
        'warningCount': warningCount,
        'flagged': appSwitchCount > 3 || tabSwitchCount > 5,
      },
    });
  }
}

// Anti-Cheat Monitor Widget
class AntiCheatMonitor extends StatefulWidget {
  final String studentId;
  final String quizId;
  final String? submissionId;
  final Function(int warningCount, int appSwitchCount, int tabSwitchCount)
  onActivityDetected;

  const AntiCheatMonitor({
    Key? key,
    required this.studentId,
    required this.quizId,
    this.submissionId,
    required this.onActivityDetected,
  }) : super(key: key);

  @override
  State<AntiCheatMonitor> createState() => AntiCheatMonitorState();
}

class AntiCheatMonitorState extends State<AntiCheatMonitor>
    with WidgetsBindingObserver {
  int _appSwitchCount = 0;
  int _tabSwitchCount = 0;
  int _warningCount = 0;
  DateTime? _lastPausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableFullscreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disableFullscreen();
    super.dispose();
  }

  void _enableFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _disableFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _handleAppSwitch();
    } else if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }

  void _handleAppSwitch() {
    _lastPausedTime = DateTime.now();
    setState(() {
      _appSwitchCount++;
      _warningCount++;
    });

    widget.onActivityDetected(_warningCount, _appSwitchCount, _tabSwitchCount);

    if (widget.submissionId != null) {
      AntiCheatService.logSuspiciousActivity(
        submissionId: widget.submissionId!,
        studentId: widget.studentId,
        quizId: widget.quizId,
        activityType: 'app_switch',
        details: 'User switched to another app',
      );
    }

    _showWarning();
  }

  void _handleAppResume() {
    if (_lastPausedTime != null) {
      final duration = DateTime.now().difference(_lastPausedTime!);
      if (duration.inSeconds > 5) {
        if (widget.submissionId != null) {
          AntiCheatService.logSuspiciousActivity(
            submissionId: widget.submissionId!,
            studentId: widget.studentId,
            quizId: widget.quizId,
            activityType: 'extended_absence',
            details: 'User was away for ${duration.inSeconds} seconds',
          );
        }
      }
    }
  }

  void _showWarning() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '⚠️ Phát hiện chuyển ứng dụng! Cảnh báo: $_warningCount',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void handleTabSwitch() {
    setState(() {
      _tabSwitchCount++;
      _warningCount++;
    });

    widget.onActivityDetected(_warningCount, _appSwitchCount, _tabSwitchCount);

    if (widget.submissionId != null) {
      AntiCheatService.logSuspiciousActivity(
        submissionId: widget.submissionId!,
        studentId: widget.studentId,
        quizId: widget.quizId,
        activityType: 'tab_switch',
        details: 'User switched browser tab',
      );
    }

    _showWarning();
  }

  int get appSwitchCount => _appSwitchCount;
  int get tabSwitchCount => _tabSwitchCount;
  int get warningCount => _warningCount;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
