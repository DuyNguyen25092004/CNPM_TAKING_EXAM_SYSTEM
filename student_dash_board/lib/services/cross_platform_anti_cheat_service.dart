// lib/services/cross_platform_anti_cheat_service.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/platform_utils.dart';

class CrossPlatformAntiCheatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Counters
  static int screenshotAttempts = 0;
  static int tabSwitchCount = 0;
  static int suspiciousKeyCombinations = 0;
  static int suspiciousMouseBehavior = 0;

  // Mouse tracking
  static List<Offset> mousePositions = [];
  static DateTime? lastMouseMove;

  // Keyboard tracking
  static Set<LogicalKeyboardKey> pressedKeys = {};

  // Tab visibility (for web)
  static bool isTabVisible = true;
  static DateTime? lastVisibilityChange;

  // ============ PATTERN DETECTION (Works on all platforms) ============

  static Map<String, dynamic> analyzeAnswerPattern({
    required Map<String, String> answers,
    required List<DateTime> answerTimestamps,
    required int totalQuestions,
  }) {
    List<String> suspiciousPatterns = [];
    int suspicionScore = 0;

    // 1. Check if too many same answers in a row
    if (answers.isNotEmpty) {
      List<String> answerList = answers.values.toList();
      int maxConsecutive = 1;
      int currentConsecutive = 1;

      for (int i = 1; i < answerList.length; i++) {
        if (answerList[i] == answerList[i - 1]) {
          currentConsecutive++;
          maxConsecutive = math.max(maxConsecutive, currentConsecutive);
        } else {
          currentConsecutive = 1;
        }
      }

      if (maxConsecutive >= 5) {
        suspiciousPatterns.add(
          'Chọn đáp án giống nhau liên tiếp $maxConsecutive lần',
        );
        suspicionScore += 30;
      }
    }

    // 2. Check answer speed
    if (answerTimestamps.length >= 2) {
      List<int> intervals = [];
      for (int i = 1; i < answerTimestamps.length; i++) {
        intervals.add(
          answerTimestamps[i].difference(answerTimestamps[i - 1]).inSeconds,
        );
      }

      double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

      if (avgInterval < 3) {
        suspiciousPatterns.add(
          'Trả lời quá nhanh (TB ${avgInterval.toStringAsFixed(1)}s/câu)',
        );
        suspicionScore += 40;
      }

      int veryFastAnswers = intervals.where((i) => i < 1).length;
      if (veryFastAnswers >= totalQuestions * 0.5) {
        suspiciousPatterns.add('$veryFastAnswers câu trả lời trong < 1 giây');
        suspicionScore += 50;
      }
    }

    // 3. Check A-B-C-D sequence
    if (answers.length >= 4) {
      List<String> answerList = answers.values.toList();
      int sequentialCount = 0;

      for (int i = 0; i < answerList.length - 3; i++) {
        List<String> sequence = ['A', 'B', 'C', 'D'];
        bool isSequential = true;

        for (int j = 0; j < 4; j++) {
          if (i + j >= answerList.length || answerList[i + j] != sequence[j]) {
            isSequential = false;
            break;
          }
        }

        if (isSequential) sequentialCount++;
      }

      if (sequentialCount > 0) {
        suspiciousPatterns.add('Phát hiện trả lời theo thứ tự A-B-C-D');
        suspicionScore += 35;
      }
    }

    return {
      'suspicionScore': suspicionScore,
      'patterns': suspiciousPatterns,
      'isSuspicious': suspicionScore >= 50,
    };
  }

  // ============ TIMING ANALYSIS (Works on all platforms) ============

  static Map<String, dynamic> analyzeQuizTiming({
    required int totalTimeSpent,
    required int quizDuration,
    required int questionCount,
    required List<int> questionTimes,
  }) {
    List<String> suspiciousTimingPatterns = [];
    int timingSuspicionScore = 0;

    // 1. Check if finished too quickly
    double completionPercentage = totalTimeSpent / (quizDuration * 60);
    if (completionPercentage < 0.3) {
      suspiciousTimingPatterns.add(
        'Hoàn thành quá nhanh (${(completionPercentage * 100).toInt()}% thời gian)',
      );
      timingSuspicionScore += 30;
    }

    // 2. Check if all questions took similar time (bot-like)
    if (questionTimes.length >= 5) {
      double avgTime =
          questionTimes.reduce((a, b) => a + b) / questionTimes.length;
      double variance = 0;

      for (var time in questionTimes) {
        variance += math.pow(time - avgTime, 2);
      }
      variance /= questionTimes.length;
      double stdDev = math.sqrt(variance);

      if (stdDev < 2) {
        suspiciousTimingPatterns.add('Thời gian trả lời quá đều (bot-like)');
        timingSuspicionScore += 40;
      }
    }

    // 3. Check for sudden time jumps
    for (int i = 1; i < questionTimes.length; i++) {
      if (questionTimes[i] > 120) {
        suspiciousTimingPatterns.add(
          'Câu ${i + 1}: Mất ${questionTimes[i]}s (có thể tìm kiếm đáp án)',
        );
        timingSuspicionScore += 20;
      }
    }

    return {
      'timingSuspicionScore': timingSuspicionScore,
      'patterns': suspiciousTimingPatterns,
      'isSuspicious': timingSuspicionScore >= 40,
    };
  }

  // ============ MOUSE TRACKING (Works on all platforms) ============

  static void trackMousePosition(Offset position) {
    mousePositions.add(position);
    lastMouseMove = DateTime.now();

    if (mousePositions.length > 100) {
      mousePositions.removeAt(0);
    }

    if (mousePositions.length >= 10) {
      bool allSamePosition = mousePositions
          .skip(mousePositions.length - 10)
          .every((pos) => pos == mousePositions.last);

      if (allSamePosition) {
        suspiciousMouseBehavior++;
      }
    }
  }

  static Map<String, dynamic> analyzeMouseBehavior() {
    if (mousePositions.length < 20) {
      return {'suspicious': false, 'reason': 'Not enough data'};
    }

    double totalDistance = 0;
    for (int i = 1; i < mousePositions.length; i++) {
      totalDistance += (mousePositions[i] - mousePositions[i - 1]).distance;
    }
    double avgDistance = totalDistance / (mousePositions.length - 1);

    if (avgDistance < 5 && mousePositions.length > 50) {
      return {
        'suspicious': true,
        'reason': 'Unnaturally precise mouse movements',
        'avgDistance': avgDistance,
      };
    }

    return {'suspicious': false, 'avgDistance': avgDistance};
  }

  // ============ KEYBOARD DETECTION (Mobile & Desktop only) ============

  static bool handleKeyEvent(KeyEvent event, BuildContext context) {
    // Only work on platforms that support hardware keyboard
    if (!PlatformUtils.supportsHardwareKeyboard) {
      return false;
    }

    if (event is KeyDownEvent) {
      pressedKeys.add(event.logicalKey);

      // Detect Alt+Tab
      if (pressedKeys.contains(LogicalKeyboardKey.altLeft) &&
          pressedKeys.contains(LogicalKeyboardKey.tab)) {
        suspiciousKeyCombinations++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Phím tắt bị vô hiệu hóa trong khi thi'),
            duration: Duration(seconds: 2),
          ),
        );
        return true;
      }

      // Detect Ctrl+C, Ctrl+V
      if (pressedKeys.contains(LogicalKeyboardKey.control)) {
        if (pressedKeys.contains(LogicalKeyboardKey.keyC) ||
            pressedKeys.contains(LogicalKeyboardKey.keyV)) {
          suspiciousKeyCombinations++;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Copy-paste bị vô hiệu hóa'),
              duration: Duration(seconds: 2),
            ),
          );
          return true;
        }
      }

      // Detect Print Screen
      if (pressedKeys.contains(LogicalKeyboardKey.printScreen)) {
        suspiciousKeyCombinations++;
        detectScreenshot(context, '', '', '');
        return true;
      }
    } else if (event is KeyUpEvent) {
      pressedKeys.remove(event.logicalKey);
    }

    return false;
  }

  // ============ SCREENSHOT DETECTION (Android only) ============

  static void detectScreenshot(
    BuildContext context,
    String submissionId,
    String studentId,
    String quizId,
  ) {
    if (!PlatformUtils.supportsScreenshotDetection) {
      return; // Only work on Android
    }

    screenshotAttempts++;

    logSuspiciousActivity(
      submissionId: submissionId,
      studentId: studentId,
      quizId: quizId,
      activityType: 'screenshot_attempt',
      details: 'Attempted to take screenshot',
      severity: 'high',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '⚠️ Phát hiện chụp màn hình! Hành vi này đã được ghi lại.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  // ============ TAB VISIBILITY (Web only) ============

  static void setupWebVisibilityListener(
    BuildContext context,
    String studentId,
    String quizId,
  ) {
    if (!PlatformUtils.isWeb) {
      return; // Only for web
    }

    // Web-specific visibility change detection would go here
    // This would require platform channel or js interop
  }

  static void onVisibilityChanged(
    bool isVisible,
    BuildContext context,
    String? submissionId,
    String studentId,
    String quizId,
  ) {
    if (PlatformUtils.isWeb) {
      isTabVisible = isVisible;

      if (!isVisible) {
        tabSwitchCount++;
        lastVisibilityChange = DateTime.now();

        if (submissionId != null) {
          logSuspiciousActivity(
            submissionId: submissionId,
            studentId: studentId,
            quizId: quizId,
            activityType: 'tab_switch',
            details: 'User switched browser tab or window',
            severity: 'medium',
          );
        }

        if (tabSwitchCount >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Cảnh báo: Đã chuyển tab $tabSwitchCount lần'),
              backgroundColor: Colors.orange[700],
            ),
          );
        }
      }
    }
  }

  // ============ RANDOMIZATION CHECK (Works on all platforms) ============

  static bool checkIfAnswersAreRandom(Map<String, String> answers) {
    if (answers.length < 10) return false;

    Map<String, int> distribution = {'A': 0, 'B': 0, 'C': 0, 'D': 0};

    for (var answer in answers.values) {
      distribution[answer] = (distribution[answer] ?? 0) + 1;
    }

    int total = answers.length;
    bool tooUniform = distribution.values.every((count) {
      double percentage = count / total;
      return (percentage - 0.25).abs() < 0.05;
    });

    return tooUniform;
  }

  // ============ LOGGING (Works on all platforms) ============

  static Future<void> logSuspiciousActivity({
    required String submissionId,
    required String studentId,
    required String quizId,
    required String activityType,
    String? details,
    required String severity,
  }) async {
    await _firestore.collection('suspicious_activities').add({
      'submissionId': submissionId,
      'studentId': studentId,
      'quizId': quizId,
      'activityType': activityType,
      'details': details,
      'severity': severity,
      'platform': PlatformUtils.platformName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ============ COMPREHENSIVE REPORT (Works on all platforms) ============

  static Future<void> generateAntiCheatReport({
    required String submissionId,
    required String studentId,
    required String quizId,
    required Map<String, String> answers,
    required List<DateTime> answerTimestamps,
    required int totalTimeSpent,
    required int quizDuration,
    required int appSwitchCount,
    required int tabSwitchCount,
    required int warningCount,
    required List<int> questionTimes,
  }) async {
    // Analyze patterns (works on all platforms)
    final patternAnalysis = analyzeAnswerPattern(
      answers: answers,
      answerTimestamps: answerTimestamps,
      totalQuestions: answers.length,
    );

    final timingAnalysis = analyzeQuizTiming(
      totalTimeSpent: totalTimeSpent,
      quizDuration: quizDuration,
      questionCount: answers.length,
      questionTimes: questionTimes,
    );

    final mouseAnalysis = analyzeMouseBehavior();
    final isRandomGuessing = checkIfAnswersAreRandom(answers);

    // Calculate total suspicion score
    int totalSuspicionScore =
        (patternAnalysis['suspicionScore'] as int) +
        (timingAnalysis['timingSuspicionScore'] as int) +
        (appSwitchCount * 10) +
        (tabSwitchCount * 5) +
        (suspiciousKeyCombinations * 15) +
        (screenshotAttempts * 25) +
        (isRandomGuessing ? 30 : 0) +
        ((mouseAnalysis['suspicious'] == true) ? 35 : 0);

    // Determine verdict
    String verdict = 'clean';
    if (totalSuspicionScore >= 100) {
      verdict = 'highly_suspicious';
    } else if (totalSuspicionScore >= 60) {
      verdict = 'suspicious';
    } else if (totalSuspicionScore >= 30) {
      verdict = 'questionable';
    }

    // Save report
    await _firestore.collection('submissions').doc(submissionId).update({
      'antiCheat': {
        'platform': PlatformUtils.platformName,
        'availableFeatures': PlatformUtils.availableAntiCheatFeatures,
        'appSwitchCount': appSwitchCount,
        'tabSwitchCount': tabSwitchCount,
        'warningCount': warningCount,
        'screenshotAttempts': screenshotAttempts,
        'suspiciousKeyCombinations': suspiciousKeyCombinations,
        'totalSuspicionScore': totalSuspicionScore,
        'verdict': verdict,
        'patternAnalysis': patternAnalysis,
        'timingAnalysis': timingAnalysis,
        'mouseAnalysis': mouseAnalysis,
        'isRandomGuessing': isRandomGuessing,
        'flagged': totalSuspicionScore >= 60,
        'requiresReview': totalSuspicionScore >= 100,
      },
    });
  }

  // Reset counters
  static void resetCounters() {
    screenshotAttempts = 0;
    tabSwitchCount = 0;
    suspiciousKeyCombinations = 0;
    suspiciousMouseBehavior = 0;
    mousePositions.clear();
    pressedKeys.clear();
  }
}
