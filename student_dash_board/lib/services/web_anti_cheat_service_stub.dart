// lib/services/web_anti_cheat_service_stub.dart
import 'package:flutter/material.dart';

// Stub implementation for non-web platforms
class WebAntiCheatService {
  static void initialize({
    required BuildContext context,
    required String studentId,
    required String quizId,
    String? submissionId,
    Function(int tabSwitches)? onTabSwitch,
    Function(String type)? onSuspiciousActivity,
  }) {
    // No-op for non-web platforms
  }

  static Map<String, dynamic> getStatistics() {
    return {
      'tabSwitchCount': 0,
      'screenshotAttempts': 0,
      'devToolsAttempts': 0,
      'copyPasteAttempts': 0,
      'isTabVisible': true,
    };
  }

  static void dispose() {
    // No-op for non-web platforms
  }

  static void resetCounters() {
    // No-op for non-web platforms
  }
}
