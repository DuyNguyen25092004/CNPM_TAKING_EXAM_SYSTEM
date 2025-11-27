// lib/services/web_anti_cheat_service.dart
import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'cross_platform_anti_cheat_service.dart';

class WebAntiCheatService {
  static StreamSubscription<html.Event>? _visibilitySubscription;
  static StreamSubscription<html.KeyboardEvent>? _keyboardSubscription;
  static StreamSubscription<html.Event>? _contextMenuSubscription;
  static StreamSubscription<html.Event>? _beforeUnloadSubscription;
  static StreamSubscription<html.Event>? _clipboardSubscription;
  static StreamSubscription<html.Event>? _focusSubscription;
  static StreamSubscription<html.Event>? _blurSubscription;

  static bool _isTabVisible = true;
  static int _tabSwitchCount = 0;
  static int _screenshotAttempts = 0;
  static int _devToolsAttempts = 0;
  static int _copyPasteAttempts = 0;
  static DateTime? _lastVisibilityChange;
  static DateTime? _lastBlurTime;

  // Debouncing to prevent multiple triggers
  static Timer? _debounceTimer;
  static bool _isProcessingVisibilityChange = false;

  // Callback functions
  static Function(int tabSwitches)? _onTabSwitch;
  static Function(String type)? _onSuspiciousActivity;

  /// Initialize web-specific anti-cheat monitoring
  static void initialize({
    required BuildContext context,
    required String studentId,
    required String quizId,
    String? submissionId,
    Function(int tabSwitches)? onTabSwitch,
    Function(String type)? onSuspiciousActivity,
  }) {
    _onTabSwitch = onTabSwitch;
    _onSuspiciousActivity = onSuspiciousActivity;

    // 1. Tab Visibility Detection
    _setupVisibilityListener(context, studentId, quizId, submissionId);

    // 2. Keyboard Shortcut Detection
    _setupKeyboardListener(context, studentId, quizId, submissionId);

    // 3. Clipboard Detection
    _setupClipboardListener(context, studentId, quizId, submissionId);

    // 4. Right-click / Context Menu Detection
    _setupContextMenuListener(context);

    // 5. Page Unload Detection
    _setupBeforeUnloadListener();

    // 6. Disable some browser features
    _disableBrowserFeatures();

    // 7. Advanced screenshot detection (DISABLED to avoid conflicts)
    // _setupAdvancedScreenshotDetection is commented out to prevent false positives

    print('🔒 Web Anti-Cheat initialized for Quiz: $quizId');
  }

  /// Setup tab visibility detection with debouncing
  static void _setupVisibilityListener(
    BuildContext context,
    String studentId,
    String quizId,
    String? submissionId,
  ) {
    _visibilitySubscription = html.document.onVisibilityChange.listen((event) {
      // Prevent processing if already handling a visibility change
      if (_isProcessingVisibilityChange) {
        return;
      }

      final isVisible = !html.document.hidden!;

      // Only count when switching AWAY from tab (visible -> hidden)
      if (_isTabVisible && !isVisible) {
        _isProcessingVisibilityChange = true;

        // Debounce to prevent multiple rapid triggers
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          _handleTabSwitchAway(context, studentId, quizId, submissionId);
          _isProcessingVisibilityChange = false;
        });
      } else if (!_isTabVisible && isVisible) {
        // User came back - only log if away too long
        _handleTabReturn(context, studentId, quizId, submissionId);

        // Important: Don't mark as processing to allow camera to resume
        _isProcessingVisibilityChange = false;
      }
    });
  }

  /// Handle tab switch away
  static void _handleTabSwitchAway(
    BuildContext context,
    String studentId,
    String quizId,
    String? submissionId,
  ) {
    _tabSwitchCount++;
    _lastVisibilityChange = DateTime.now();
    _isTabVisible = false;

    print('⚠️ Tab switched away! Count: $_tabSwitchCount');

    // Log to Firestore
    if (submissionId != null) {
      CrossPlatformAntiCheatService.logSuspiciousActivity(
        submissionId: submissionId,
        studentId: studentId,
        quizId: quizId,
        activityType: 'tab_switch_away',
        details: 'User switched to another tab/window',
        severity: 'medium',
      );
    }

    // Show warning
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '⚠️ Phát hiện chuyển tab! Cảnh báo: $_tabSwitchCount',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 3),
      ),
    );

    // Single callback to update UI
    _onTabSwitch?.call(_tabSwitchCount);
  }

  /// Handle tab return
  static void _handleTabReturn(
    BuildContext context,
    String studentId,
    String quizId,
    String? submissionId,
  ) {
    _isTabVisible = true;
    print('✅ User returned to tab');

    // Only log if user was away for more than 10 seconds
    if (_lastVisibilityChange != null) {
      final duration = DateTime.now().difference(_lastVisibilityChange!);

      if (duration.inSeconds > 10) {
        print('⚠️ User was away for ${duration.inSeconds} seconds');

        if (submissionId != null) {
          CrossPlatformAntiCheatService.logSuspiciousActivity(
            submissionId: submissionId,
            studentId: studentId,
            quizId: quizId,
            activityType: 'extended_tab_absence',
            details: 'User was away for ${duration.inSeconds} seconds',
            severity: 'high',
          );
        }

        // Show info message (NOT a warning)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ℹ️ Bạn đã rời khỏi tab ${duration.inSeconds} giây',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.blue[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Setup keyboard shortcut detection
  static void _setupKeyboardListener(
    BuildContext context,
    String studentId,
    String quizId,
    String? submissionId,
  ) {
    _keyboardSubscription = html.document.onKeyDown.listen((event) {
      bool shouldPrevent = false;
      String? detectedAction;

      // ============ SCREENSHOT DETECTION ============
      if (event.metaKey && event.shiftKey && event.key == 'S') {
        shouldPrevent = true;
        detectedAction = 'snipping_tool';
        _screenshotAttempts++;
      } else if (event.ctrlKey && event.shiftKey && event.keyCode == 83) {
        shouldPrevent = true;
        detectedAction = 'browser_screenshot';
        _screenshotAttempts++;
      } else if (event.keyCode == 44 || event.key == 'PrintScreen') {
        shouldPrevent = true;
        detectedAction = 'print_screen';
        _screenshotAttempts++;
      }
      // ============ DEVTOOLS DETECTION ============
      else if (event.ctrlKey && event.shiftKey && event.keyCode == 73) {
        shouldPrevent = true;
        detectedAction = 'devtools_attempt';
        _devToolsAttempts++;
      } else if (event.keyCode == 123) {
        shouldPrevent = true;
        detectedAction = 'devtools_f12';
        _devToolsAttempts++;
      } else if (event.ctrlKey && event.shiftKey && event.keyCode == 74) {
        shouldPrevent = true;
        detectedAction = 'devtools_console';
        _devToolsAttempts++;
      } else if (event.ctrlKey && event.shiftKey && event.keyCode == 67) {
        shouldPrevent = true;
        detectedAction = 'inspect_element';
        _devToolsAttempts++;
      }
      // ============ COPY/PASTE DETECTION ============
      else if (event.ctrlKey && event.keyCode == 85) {
        shouldPrevent = true;
        detectedAction = 'view_source';
      } else if (event.ctrlKey && event.keyCode == 67 && !event.shiftKey) {
        shouldPrevent = true;
        detectedAction = 'copy_attempt';
        _copyPasteAttempts++;
      } else if (event.ctrlKey && event.keyCode == 86) {
        shouldPrevent = true;
        detectedAction = 'paste_attempt';
        _copyPasteAttempts++;
      } else if (event.ctrlKey && event.keyCode == 88) {
        shouldPrevent = true;
        detectedAction = 'cut_attempt';
        _copyPasteAttempts++;
      } else if (event.ctrlKey && event.keyCode == 65) {
        shouldPrevent = true;
        detectedAction = 'select_all';
      }
      // ============ PRINT DETECTION ============
      else if (event.ctrlKey && event.keyCode == 83 && !event.shiftKey) {
        shouldPrevent = true;
        detectedAction = 'save_attempt';
      } else if (event.ctrlKey && event.keyCode == 80) {
        shouldPrevent = true;
        detectedAction = 'print_attempt';
        _screenshotAttempts++;
      }

      if (shouldPrevent) {
        event.preventDefault();
        event.stopPropagation();

        _handleKeyboardViolation(
          context,
          studentId,
          quizId,
          submissionId,
          detectedAction!,
        );
      }
    });
  }

  /// Handle keyboard violation
  static void _handleKeyboardViolation(
    BuildContext context,
    String studentId,
    String quizId,
    String? submissionId,
    String detectedAction,
  ) {
    print('🚫 Blocked: $detectedAction');

    // Log to Firestore
    if (submissionId != null) {
      CrossPlatformAntiCheatService.logSuspiciousActivity(
        submissionId: submissionId,
        studentId: studentId,
        quizId: quizId,
        activityType: detectedAction,
        details: 'Keyboard shortcut blocked: $detectedAction',
        severity: _getSeverityLevel(detectedAction),
      );
    }

    // Show warning
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.block, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _getWarningMessage(detectedAction),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 2),
      ),
    );

    // Call callback only once per violation
    _onSuspiciousActivity?.call(detectedAction);
  }

  /// Setup clipboard detection
  static void _setupClipboardListener(
    BuildContext context,
    String studentId,
    String quizId,
    String? submissionId,
  ) {
    _clipboardSubscription = html.document.onCopy.listen((event) {
      event.preventDefault();
      _copyPasteAttempts++;

      print('⚠️ Copy via context menu detected!');

      if (submissionId != null) {
        CrossPlatformAntiCheatService.logSuspiciousActivity(
          submissionId: submissionId,
          studentId: studentId,
          quizId: quizId,
          activityType: 'clipboard_copy',
          details: 'User tried to copy text via clipboard',
          severity: 'medium',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Không thể copy nội dung câu hỏi!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      _onSuspiciousActivity?.call('clipboard_copy');
    });
  }

  /// Setup right-click detection
  static void _setupContextMenuListener(BuildContext context) {
    _contextMenuSubscription = html.document.onContextMenu.listen((event) {
      event.preventDefault();
    });
  }

  /// Setup page unload warning
  static void _setupBeforeUnloadListener() {
    _beforeUnloadSubscription = html.window.onBeforeUnload.listen((event) {
      event.preventDefault();
      try {
        (event as dynamic).returnValue =
            'Bạn có chắc muốn rời khỏi trang? Bài thi sẽ không được lưu.';
      } catch (e) {
        // Ignore if not supported
      }
    });
  }

  /// Disable some browser features using CSS
  static void _disableBrowserFeatures() {
    final style = html.document.createElement('style') as html.StyleElement;
    style.text = '''
      body {
        user-select: none;
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
      }
      
      img {
        pointer-events: none;
        -webkit-user-drag: none;
        user-drag: none;
      }
    ''';
    html.document.head?.append(style);
  }

  // Helper methods
  static String _getSeverityLevel(String action) {
    if (action.contains('print') ||
        action.contains('screenshot') ||
        action.contains('snipping')) {
      return 'high';
    } else if (action.contains('devtools') || action.contains('inspect')) {
      return 'high';
    } else if (action.contains('copy') || action.contains('paste')) {
      return 'medium';
    }
    return 'low';
  }

  static String _getWarningMessage(String action) {
    final messages = {
      'snipping_tool': '⚠️ Snipping Tool bị chặn!',
      'browser_screenshot': '⚠️ Chụp màn hình bị chặn!',
      'print_screen': '⚠️ Print Screen bị chặn!',
      'print_attempt': '⚠️ In trang bị chặn!',
      'devtools_attempt': '⚠️ DevTools bị vô hiệu hóa!',
      'devtools_f12': '⚠️ F12 bị vô hiệu hóa!',
      'devtools_console': '⚠️ Console bị vô hiệu hóa!',
      'inspect_element': '⚠️ Inspect bị vô hiệu hóa!',
      'copy_attempt': '⚠️ Copy bị vô hiệu hóa!',
      'paste_attempt': '⚠️ Paste bị vô hiệu hóa!',
      'cut_attempt': '⚠️ Cut bị vô hiệu hóa!',
      'select_all': '⚠️ Select All bị vô hiệu hóa!',
      'save_attempt': '⚠️ Lưu trang bị vô hiệu hóa!',
      'view_source': '⚠️ View Source bị vô hiệu hóa!',
    };
    return messages[action] ?? '⚠️ Phím tắt bị vô hiệu hóa!';
  }

  /// Get current statistics
  static Map<String, dynamic> getStatistics() {
    return {
      'tabSwitchCount': _tabSwitchCount,
      'screenshotAttempts': _screenshotAttempts,
      'devToolsAttempts': _devToolsAttempts,
      'copyPasteAttempts': _copyPasteAttempts,
      'isTabVisible': _isTabVisible,
    };
  }

  /// Cleanup and dispose listeners
  static void dispose() {
    _debounceTimer?.cancel();
    _visibilitySubscription?.cancel();
    _keyboardSubscription?.cancel();
    _contextMenuSubscription?.cancel();
    _beforeUnloadSubscription?.cancel();
    _clipboardSubscription?.cancel();
    _focusSubscription?.cancel();
    _blurSubscription?.cancel();

    _debounceTimer = null;
    _visibilitySubscription = null;
    _keyboardSubscription = null;
    _contextMenuSubscription = null;
    _beforeUnloadSubscription = null;
    _clipboardSubscription = null;
    _focusSubscription = null;
    _blurSubscription = null;

    print('🔓 Web Anti-Cheat disposed');
  }

  /// Reset counters
  static void resetCounters() {
    _tabSwitchCount = 0;
    _screenshotAttempts = 0;
    _devToolsAttempts = 0;
    _copyPasteAttempts = 0;
    _isTabVisible = true;
    _lastVisibilityChange = null;
    _lastBlurTime = null;
    _isProcessingVisibilityChange = false;
  }
}
