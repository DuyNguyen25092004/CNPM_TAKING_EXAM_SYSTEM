// lib/widgets/camera_permission_dialog.dart
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/camera_proctoring_service.dart';

class CameraPermissionDialog extends StatefulWidget {
  final VoidCallback onCameraReady;

  const CameraPermissionDialog({Key? key, required this.onCameraReady})
    : super(key: key);

  @override
  State<CameraPermissionDialog> createState() => _CameraPermissionDialogState();
}

class _CameraPermissionDialogState extends State<CameraPermissionDialog> {
  bool _isInitializing = false;
  String? _errorMessage;
  String? _cameraViewType;
  bool _isCameraReady = false;
  bool _isFaceDetectionReady = false;
  bool _isWarmupComplete = false; // 🔥 NEW: Track warm-up completion
  String? _faceWarning;
  Timer? _statusCheckTimer;

  // Button ready state
  bool _isButtonReady = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _faceWarning = null;
      _isButtonReady = false;
      _isWarmupComplete = false; // 🔥 Reset warm-up state
    });

    final result = await CameraProctoringService.initializeCamera(
      onFaceWarning: (message) {
        if (mounted) {
          setState(() {
            _faceWarning = message;
          });
        }
      },
      onFaceDetected: () {
        if (mounted) {
          setState(() {
            _faceWarning = null;
          });
        }
      },
      onNoFaceDetected: () {
        if (mounted) {
          setState(() {
            _faceWarning = 'Không phát hiện khuôn mặt';
          });
        }
      },
      // 🔥 NEW: Warm-up complete callback
      onWarmupComplete: () {
        print('✅ Warm-up complete callback triggered!');
        if (mounted) {
          setState(() {
            _isWarmupComplete = true;
            _isButtonReady = true; // Enable button immediately
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Hệ thống đã sẵn sàng! Bạn có thể bắt đầu thi.'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );

    if (mounted) {
      if (result['success']) {
        setState(() {
          _cameraViewType = result['viewType'];
          _isCameraReady = true;
          _isInitializing = false;
        });

        // Start continuous status checking
        _startStatusMonitoring();
      } else {
        setState(() {
          _errorMessage = result['error'];
          _isInitializing = false;
        });
      }
    }
  }

  // Monitor status for face detection ready indicator
  void _startStatusMonitoring() {
    _statusCheckTimer?.cancel();

    _statusCheckTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final status = CameraProctoringService.getCameraStatus();
      final newFaceDetectionReady = status['isFaceDetectionReady'] ?? false;
      final newWarmupComplete = status['isWarmupComplete'] ?? false;

      bool needsUpdate = false;

      // Update face detection ready state
      if (newFaceDetectionReady != _isFaceDetectionReady) {
        _isFaceDetectionReady = newFaceDetectionReady;
        needsUpdate = true;

        if (newFaceDetectionReady) {
          print('✅ Face detection model loaded');
        }
      }

      // Update warm-up complete state
      if (newWarmupComplete != _isWarmupComplete) {
        _isWarmupComplete = newWarmupComplete;
        _isButtonReady = newWarmupComplete; // Enable button when warm-up done
        needsUpdate = true;

        if (newWarmupComplete) {
          print('✅ Warm-up complete, button enabled!');
        }
      }

      if (needsUpdate && mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.videocam,
                    color: Colors.blue[700],
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yêu cầu Camera & Nhận diện khuôn mặt',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Camera sẽ giám sát khuôn mặt trong suốt bài thi',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Camera preview
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildCameraPreview(),
              ),
            ),
            const SizedBox(height: 16),

            // Face detection status
            if (_isFaceDetectionReady && _faceWarning != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _faceWarning!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),

            // Instructions or error
            if (_errorMessage != null)
              _buildErrorBox()
            else if (_isCameraReady && !_isFaceDetectionReady)
              _buildLoadingBox(
                'Đang tải mô hình nhận diện khuôn mặt...',
                'Vui lòng đợi, quá trình này có thể mất 5-15 giây',
              )
            else if (_isCameraReady &&
                _isFaceDetectionReady &&
                !_isWarmupComplete)
              _buildLoadingBox(
                'Đang khởi động face detection...',
                'Đang thực hiện warm-up, vui lòng đợi 1-2 giây',
              )
            else if (_isCameraReady &&
                _isFaceDetectionReady &&
                _isWarmupComplete)
              _buildReadyBox(),

            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lỗi Camera',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: TextStyle(fontSize: 13, color: Colors.red[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: Colors.blue[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBox(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Camera và nhận diện khuôn mặt đã sẵn sàng!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Đảm bảo khuôn mặt luôn trong khung hình\n'
                  '• Không để người khác vào camera\n'
                  '• Ngồi ở nơi có ánh sáng tốt',
                  style: TextStyle(fontSize: 12, color: Colors.green[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // 🔥 Button is ready only after warm-up is complete
    final bool canStartQuiz =
        _isCameraReady &&
        _isFaceDetectionReady &&
        _isWarmupComplete &&
        _isButtonReady;

    if (_errorMessage != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isInitializing ? null : _initializeCamera,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        const SizedBox(width: 12),

        // Debug button (only show when loading)
        if (_isCameraReady && (!_isFaceDetectionReady || !_isWarmupComplete))
          TextButton.icon(
            onPressed: () {
              final status = CameraProctoringService.getCameraStatus();
              final debugInfo =
                  '''
Ready: ${status['isFaceDetectionReady']}
Warm-up: ${status['isWarmupComplete']}
Count: ${status['warmupDetectionCount']}
              ''';
              print('🔍 Status: $debugInfo');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(debugInfo),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.bug_report, size: 16),
            label: const Text('Debug', style: TextStyle(fontSize: 12)),
          ),

        const SizedBox(width: 12),

        // 🔥 FIX: Improved start button with better visual feedback
        ElevatedButton.icon(
          onPressed: canStartQuiz
              ? () {
                  Navigator.pop(context);
                  widget.onCameraReady();
                }
              : null,
          icon: canStartQuiz
              ? const Icon(Icons.play_arrow)
              : const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
          label: Text(canStartQuiz ? 'Bắt đầu thi' : 'Đang chuẩn bị...'),
          style: ElevatedButton.styleFrom(
            backgroundColor: canStartQuiz ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            // 🔥 Add visual feedback
            elevation: canStartQuiz ? 2 : 0,
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Đang khởi động camera...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Camera không khả dụng',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    if (_isCameraReady && _cameraViewType != null && kIsWeb) {
      return HtmlElementView(viewType: _cameraViewType!);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Chờ camera...', style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }
}
