// lib/utils/platform_utils.dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformUtils {
  // Check if running on web
  static bool get isWeb => kIsWeb;

  // Check if running on mobile (Android or iOS)
  static bool get isMobile => !kIsWeb && (isAndroid || isIOS);

  // Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  // Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  // Check if running on desktop
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  // Check if platform supports app lifecycle detection
  static bool get supportsAppLifecycle => isMobile;

  // Check if platform supports hardware keyboard detection
  static bool get supportsHardwareKeyboard => !isWeb;

  // Check if platform supports mouse tracking
  static bool get supportsMouseTracking => true; // All platforms support this

  // Check if platform supports fullscreen mode
  static bool get supportsFullscreen => isMobile;

  // Check if platform supports screenshot detection
  static bool get supportsScreenshotDetection =>
      isAndroid; // Only Android has reliable detection

  // Get platform name for logging
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  // Get available anti-cheat features for current platform
  static List<String> get availableAntiCheatFeatures {
    List<String> features = [
      'Pattern Analysis',
      'Timing Analysis',
      'Answer Tracking',
    ];

    if (supportsAppLifecycle) {
      features.add('App Switch Detection');
    }

    if (supportsHardwareKeyboard) {
      features.add('Keyboard Shortcut Blocking');
    }

    if (supportsMouseTracking) {
      features.add('Mouse Behavior Analysis');
    }

    if (supportsFullscreen) {
      features.add('Fullscreen Mode');
    }

    if (supportsScreenshotDetection) {
      features.add('Screenshot Detection');
    }

    if (isWeb) {
      features.add('Tab Visibility Detection');
    }

    return features;
  }
}
