// lib/services/camera_proctoring_service.dart
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart' show kIsWeb;

class CameraProctoringService {
  static html.MediaStream? _mediaStream;
  static html.VideoElement? _videoElement;
  static html.CanvasElement? _canvasElement;
  static bool _isCameraActive = false;
  static String? _videoViewType;
  static Timer? _faceDetectionTimer;
  static bool _isFaceDetectionReady = false;
  static int _noFaceDetectedCount = 0;
  static DateTime? _lastFaceDetectedTime;
  static int _modelLoadAttempts = 0;
  static const int _maxModelLoadAttempts = 10;

  // 🔥 NEW: Track if warm-up is complete
  static bool _isWarmupComplete = false;
  static int _warmupDetectionCount = 0;

  // Callbacks
  static Function(String message)? _onFaceWarning;
  static Function()? _onFaceDetected;
  static Function()? _onNoFaceDetected;
  static Function()? _onWarmupComplete; // 🔥 NEW callback

  /// Check if camera is currently active
  static bool get isCameraActive => _isCameraActive;

  /// Check if face detection is ready
  static bool get isFaceDetectionReady => _isFaceDetectionReady;

  /// 🔥 NEW: Check if warm-up is complete
  static bool get isWarmupComplete => _isWarmupComplete;

  /// Initialize camera and face detection
  static Future<Map<String, dynamic>> initializeCamera({
    Function(String message)? onFaceWarning,
    Function()? onFaceDetected,
    Function()? onNoFaceDetected,
    Function()? onWarmupComplete, // 🔥 NEW parameter
  }) async {
    if (!kIsWeb) {
      return {
        'success': false,
        'error': 'Camera proctoring only works on web platform',
      };
    }

    // Set callbacks
    _onFaceWarning = onFaceWarning;
    _onFaceDetected = onFaceDetected;
    _onNoFaceDetected = onNoFaceDetected;
    _onWarmupComplete = onWarmupComplete; // 🔥 NEW

    // 🔥 Reset warm-up state
    _isWarmupComplete = false;
    _warmupDetectionCount = 0;

    try {
      // Request camera permission
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        return {
          'success': false,
          'error': 'MediaDevices not supported in this browser',
        };
      }

      // Get user media (camera) with constraints
      _mediaStream = await mediaDevices.getUserMedia({
        'video': {
          'width': {'ideal': 640},
          'height': {'ideal': 480},
          'facingMode': 'user',
          'frameRate': {'ideal': 30},
        },
        'audio': false,
      });

      // Create video element
      _videoElement = html.VideoElement()
        ..srcObject = _mediaStream
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)'; // Mirror effect

      // Create canvas for face detection overlay
      _canvasElement = html.CanvasElement()
        ..width = 640
        ..height = 480
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.transform = 'scaleX(-1)'
        ..style.pointerEvents = 'none';

      // Create container div
      final container = html.DivElement()
        ..style.position = 'relative'
        ..style.width = '100%'
        ..style.height = '100%'
        ..append(_videoElement!)
        ..append(_canvasElement!);

      // Force video to play
      await _videoElement!.play();

      // Register view
      _videoViewType = 'camera-view-${DateTime.now().millisecondsSinceEpoch}';
      ui_web.platformViewRegistry.registerViewFactory(
        _videoViewType!,
        (int viewId) => container,
      );

      _isCameraActive = true;
      _modelLoadAttempts = 0;

      // Initialize face detection after video is ready
      _videoElement!.onLoadedMetadata.listen((event) {
        print('✅ Video metadata loaded, initializing face detection...');
        _initializeFaceDetection();
      });

      // Also try to initialize immediately in case metadata is already loaded
      if (_videoElement!.readyState >= 2) {
        print('✅ Video already ready, initializing face detection...');
        _initializeFaceDetection();
      }

      print('✅ Camera initialized successfully');
      _monitorCameraStatus();

      return {'success': true, 'viewType': _videoViewType};
    } catch (e) {
      print('❌ Camera initialization failed: $e');

      String errorMessage = 'Không thể truy cập camera';
      if (e.toString().contains('NotAllowedError') ||
          e.toString().contains('PermissionDenied')) {
        errorMessage =
            'Bạn đã từ chối quyền truy cập camera. Vui lòng cho phép truy cập camera trong cài đặt trình duyệt.';
      } else if (e.toString().contains('NotFoundError')) {
        errorMessage = 'Không tìm thấy camera trên thiết bị của bạn.';
      } else if (e.toString().contains('NotReadableError')) {
        errorMessage = 'Camera đang được sử dụng bởi ứng dụng khác.';
      }

      return {'success': false, 'error': errorMessage};
    }
  }

  /// Initialize TensorFlow.js Face Detection
  static void _initializeFaceDetection() {
    try {
      _modelLoadAttempts++;
      print(
        '🔍 Initializing face detection (attempt $_modelLoadAttempts/$_maxModelLoadAttempts)...',
      );

      // Check if TensorFlow.js and face detection model are loaded
      final tfReady = js.context.hasProperty('tf');
      final faceDetectionReady = js.context.hasProperty('faceDetection');
      final loadFunctionExists = js.context.hasProperty(
        'loadFaceDetectionModel',
      );

      print('📊 TensorFlow.js ready: $tfReady');
      print('📊 Face Detection API ready: $faceDetectionReady');
      print('📊 Load function exists: $loadFunctionExists');

      if (!tfReady) {
        print('⚠️ TensorFlow.js not loaded yet');
        _scheduleFaceDetectionRetry();
        return;
      }

      if (!faceDetectionReady) {
        print('⚠️ Face Detection API not loaded yet');
        _scheduleFaceDetectionRetry();
        return;
      }

      if (!loadFunctionExists) {
        print('⚠️ loadFaceDetectionModel function not found');
        _scheduleFaceDetectionRetry();
        return;
      }

      print('🔍 Loading face detection model...');

      // Load MediaPipe Face Detection model
      js.context.callMethod('loadFaceDetectionModel', [
        js.allowInterop((model) {
          print('✅ Face detection model loaded successfully!');
          _isFaceDetectionReady = true;
          _modelLoadAttempts = 0;
          _startFaceDetection();

          // 🔥 NEW: Start warm-up process
          _performWarmup();
        }),
        js.allowInterop((error) {
          print('❌ Failed to load face detection model: $error');
          _scheduleFaceDetectionRetry();
        }),
      ]);
    } catch (e) {
      print('❌ Face detection initialization error: $e');
      _scheduleFaceDetectionRetry();
    }
  }

  /// 🔥 NEW: Perform warm-up detections
  static void _performWarmup() {
    print('🔥 Starting face detection warm-up...');

    // Run several quick detections to warm up the model
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isCameraActive || !_isFaceDetectionReady) {
        timer.cancel();
        return;
      }

      _warmupDetectionCount++;
      print('🔥 Warm-up detection #$_warmupDetectionCount');

      // Perform detection
      _detectFaceForWarmup();

      // After 3-5 successful detections, consider warm-up complete
      if (_warmupDetectionCount >= 3) {
        timer.cancel();
        _isWarmupComplete = true;
        print('✅ Warm-up complete! Face detection is fully ready.');

        // Notify via callback
        if (_onWarmupComplete != null) {
          _onWarmupComplete!();
        }
      }
    });
  }

  /// 🔥 NEW: Warm-up detection (doesn't trigger callbacks)
  static void _detectFaceForWarmup() {
    if (_videoElement == null || _canvasElement == null) return;

    try {
      js.context.callMethod('detectFaces', [
        _videoElement,
        _canvasElement,
        js.allowInterop((dynamic faces) {
          try {
            final faceCount = faces is int ? faces : (faces as num).toInt();
            print('🔥 Warm-up detected $faceCount face(s)');
          } catch (e) {
            print('⚠️ Warm-up detection error: $e');
          }
        }),
      ]);
    } catch (e) {
      print('⚠️ Warm-up face detection error: $e');
    }
  }

  /// Retry face detection initialization
  static void _scheduleFaceDetectionRetry() {
    if (_modelLoadAttempts >= _maxModelLoadAttempts) {
      print(
        '❌ Max retry attempts reached. Face detection initialization failed.',
      );
      return;
    }

    final delay = Duration(seconds: 2 * _modelLoadAttempts.clamp(1, 5));
    print('🔄 Retrying in ${delay.inSeconds} seconds...');

    Timer(delay, () {
      if (_isCameraActive && !_isFaceDetectionReady) {
        print('🔄 Retrying face detection initialization...');
        _initializeFaceDetection();
      }
    });
  }

  /// Start continuous face detection
  static void _startFaceDetection() {
    if (!_isFaceDetectionReady || _videoElement == null) {
      return;
    }

    // Run detection every 500ms (after warm-up)
    _faceDetectionTimer?.cancel();
    _faceDetectionTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (!_isCameraActive || !_isFaceDetectionReady) {
        timer.cancel();
        return;
      }

      // Only run normal detection after warm-up
      if (_isWarmupComplete) {
        _detectFace();
      }
    });

    print('🔍 Face detection started');
  }

  /// Detect face in current video frame
  static void _detectFace() {
    if (_videoElement == null || _canvasElement == null) return;

    try {
      // Call JavaScript face detection
      js.context.callMethod('detectFaces', [
        _videoElement,
        _canvasElement,
        js.allowInterop((dynamic faces) {
          try {
            final faceCount = faces is int ? faces : (faces as num).toInt();
            _handleFaceDetectionResult(faceCount);
          } catch (e) {
            print('⚠️ Error parsing face count: $e');
            _handleFaceDetectionResult(0);
          }
        }),
      ]);
    } catch (e) {
      print('⚠️ Face detection error: $e');
    }
  }

  /// Handle face detection results
  static void _handleFaceDetectionResult(int faceCount) {
    if (faceCount > 0) {
      // Face detected
      _lastFaceDetectedTime = DateTime.now();

      // Only reset and call if previously no face
      if (_noFaceDetectedCount > 0) {
        print('✅ Face detected again after $_noFaceDetectedCount warnings');
        _noFaceDetectedCount = 0;
        if (_onFaceDetected != null) {
          _onFaceDetected!();
        }
      }

      if (faceCount > 1) {
        print('⚠️ Multiple faces detected: $faceCount');
        if (_onFaceWarning != null) {
          _onFaceWarning!('⚠️ Phát hiện nhiều khuôn mặt! ($faceCount người)');
        }
      }
    } else {
      // No face detected
      _noFaceDetectedCount++;

      if (_noFaceDetectedCount >= 1) {
        print('❌ No face detected for 1+ seconds');

        if (_onNoFaceDetected != null) {
          _onNoFaceDetected!();
        }

        if (_onFaceWarning != null) {
          _onFaceWarning!(
            '⚠️ Không phát hiện khuôn mặt! Vui lòng quay lại camera.',
          );
        }
      }
    }
  }

  /// Monitor camera status
  static void _monitorCameraStatus() {
    if (_mediaStream == null) return;

    final videoTracks = _mediaStream!.getVideoTracks();
    if (videoTracks.isEmpty) return;

    final track = videoTracks.first;

    track.onEnded.listen((event) {
      print('⚠️ Camera track ended - attempting restart...');
      _handleCameraEnded();
    });

    // Periodic health check
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isCameraActive) {
        timer.cancel();
        return;
      }

      if (track.enabled == false) {
        print('⚠️ Re-enabling camera track');
        track.enabled = true;
      }
    });
  }

  /// Handle camera ended
  static void _handleCameraEnded() async {
    print('🔄 Auto-restarting camera after track ended...');
    _isCameraActive = false;
    _isFaceDetectionReady = false;
    _isWarmupComplete = false; // 🔥 Reset warm-up

    await Future.delayed(const Duration(milliseconds: 500));

    final result = await initializeCamera(
      onFaceWarning: _onFaceWarning,
      onFaceDetected: _onFaceDetected,
      onNoFaceDetected: _onNoFaceDetected,
      onWarmupComplete: _onWarmupComplete, // 🔥 Pass callback
    );

    if (result['success']) {
      print('✅ Camera auto-restart successful');
    } else {
      print('❌ Camera auto-restart failed: ${result['error']}');
    }
  }

  /// Restart camera if it freezes
  static Future<Map<String, dynamic>> restartCamera() async {
    print('🔄 Restarting camera...');
    await stopCamera();
    await Future.delayed(const Duration(milliseconds: 500));
    return await initializeCamera(
      onFaceWarning: _onFaceWarning,
      onFaceDetected: _onFaceDetected,
      onNoFaceDetected: _onNoFaceDetected,
      onWarmupComplete: _onWarmupComplete, // 🔥 Pass callback
    );
  }

  /// Stop camera and release resources
  static Future<void> stopCamera() async {
    _faceDetectionTimer?.cancel();
    _faceDetectionTimer = null;

    if (_mediaStream != null) {
      final tracks = _mediaStream!.getTracks();
      for (var track in tracks) {
        track.stop();
      }
      _mediaStream = null;
    }

    _videoElement?.pause();
    _videoElement?.srcObject = null;
    _videoElement = null;
    _canvasElement = null;

    _isCameraActive = false;
    _isFaceDetectionReady = false;
    _isWarmupComplete = false; // 🔥 Reset warm-up
    _warmupDetectionCount = 0;
    _videoViewType = null;
    _noFaceDetectedCount = 0;
    _lastFaceDetectedTime = null;
    _modelLoadAttempts = 0;

    print('🔴 Camera stopped');
  }

  /// Check if browser supports camera
  static bool isCameraSupported() {
    if (!kIsWeb) return false;
    return html.window.navigator.mediaDevices != null;
  }

  /// Get camera status
  static Map<String, dynamic> getCameraStatus() {
    bool isPlaying = false;
    if (_videoElement != null) {
      isPlaying =
          !_videoElement!.paused &&
          !_videoElement!.ended &&
          _videoElement!.readyState > 2;
    }

    return {
      'isActive': _isCameraActive,
      'isSupported': isCameraSupported(),
      'viewType': _videoViewType,
      'isPlaying': isPlaying,
      'hasStream': _mediaStream != null,
      'hasVideoElement': _videoElement != null,
      'isFaceDetectionReady': _isFaceDetectionReady,
      'isWarmupComplete': _isWarmupComplete, // 🔥 NEW
      'warmupDetectionCount': _warmupDetectionCount, // 🔥 NEW
      'noFaceCount': _noFaceDetectedCount,
      'lastFaceDetected': _lastFaceDetectedTime?.toString(),
      'modelLoadAttempts': _modelLoadAttempts,
    };
  }

  /// Get face detection statistics
  static Map<String, dynamic> getFaceDetectionStats() {
    return {
      'isFaceDetectionReady': _isFaceDetectionReady,
      'isWarmupComplete': _isWarmupComplete, // 🔥 NEW
      'warmupDetectionCount': _warmupDetectionCount, // 🔥 NEW
      'noFaceDetectedCount': _noFaceDetectedCount,
      'lastFaceDetectedTime': _lastFaceDetectedTime,
      'secondsSinceLastFace': _lastFaceDetectedTime != null
          ? DateTime.now().difference(_lastFaceDetectedTime!).inSeconds
          : null,
      'modelLoadAttempts': _modelLoadAttempts,
    };
  }

  /// Get debug info
  static String getDebugInfo() {
    final status = getCameraStatus();
    final faceStats = getFaceDetectionStats();

    // Check JavaScript environment
    final tfReady = kIsWeb ? js.context.hasProperty('tf') : false;
    final faceDetectionReady = kIsWeb
        ? js.context.hasProperty('faceDetection')
        : false;
    final loadFunctionExists = kIsWeb
        ? js.context.hasProperty('loadFaceDetectionModel')
        : false;

    return '''
🎥 Camera Debug Info:
- Active: ${status['isActive']}
- Playing: ${status['isPlaying']}
- Face Detection Ready: ${faceStats['isFaceDetectionReady']}
- Warm-up Complete: ${faceStats['isWarmupComplete']} ✨
- Warm-up Count: ${faceStats['warmupDetectionCount']} ✨
- No Face Count: ${faceStats['noFaceDetectedCount']}
- Last Face: ${faceStats['lastFaceDetectedTime'] ?? 'Never'}
- Seconds Since Face: ${faceStats['secondsSinceLastFace'] ?? 'N/A'}
- Model Load Attempts: ${status['modelLoadAttempts']}

📦 JavaScript Libraries:
- TensorFlow.js: $tfReady
- Face Detection API: $faceDetectionReady
- Load Function: $loadFunctionExists
''';
  }
}
