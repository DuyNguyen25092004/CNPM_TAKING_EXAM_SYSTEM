// lib/screens/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../student/class_list_page.dart';
import '../teacher/teacher_panel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    super.dispose();
  }

  /// Xử lý đăng nhập Microsoft
  Future<void> _handleMicrosoftLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔐 Attempting Microsoft login...');

      // Tạo Microsoft Provider
      final microsoftProvider = OAuthProvider('microsoft.com');

      // Thêm các scope cần thiết
      microsoftProvider.addScope('email');
      microsoftProvider.addScope('profile');

      // ⚡ QUAN TRỌNG: Thêm custom parameters để force account selection
      microsoftProvider.setCustomParameters({
        'prompt': 'select_account', // Buộc hiển thị màn hình chọn tài khoản
        'login_hint': '', // Xóa hint về tài khoản trước đó
      });

      UserCredential? userCredential;

      // Kiểm tra platform và sử dụng method phù hợp
      if (kIsWeb) {
        // Trên Web: Sử dụng signInWithPopup
        print('🌐 Using signInWithPopup for Web');
        userCredential = await _auth.signInWithPopup(microsoftProvider);
      } else {
        // Trên Mobile/Desktop: Sử dụng signInWithProvider
        print('📱 Using signInWithProvider for Mobile');
        userCredential = await _auth.signInWithProvider(microsoftProvider);
      }

      if (userCredential?.user == null) {
        throw Exception('Đăng nhập Microsoft thất bại');
      }

      final user = userCredential!.user!;
      print('✅ Microsoft authentication successful: ${user.uid}');
      print('📧 Email: ${user.email}');
      print('👤 Display Name: ${user.displayName}');

      // Xử lý đăng nhập thành công
      await _handleSuccessfulLogin(user);

    } on FirebaseAuthException catch (e) {
      print('❌ Microsoft Auth Error: ${e.code}');
      setState(() {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            _errorMessage = 'Tài khoản đã tồn tại với phương thức đăng nhập khác. Vui lòng đăng nhập bằng email/password.';
            break;
          case 'invalid-credential':
            _errorMessage = 'Thông tin đăng nhập Microsoft không hợp lệ';
            break;
          case 'operation-not-allowed':
            _errorMessage = 'Đăng nhập Microsoft chưa được kích hoạt. Vui lòng liên hệ quản trị viên.';
            break;
          case 'user-disabled':
            _errorMessage = 'Tài khoản đã bị vô hiệu hóa';
            break;
          case 'popup-closed-by-user':
            _errorMessage = 'Đăng nhập bị hủy bỏ';
            break;
          case 'popup-blocked':
            _errorMessage = 'Trình duyệt đã chặn popup. Vui lòng cho phép popup và thử lại.';
            break;
          default:
            _errorMessage = 'Đăng nhập Microsoft thất bại: ${e.message}';
        }
      });
    } catch (e) {
      print('❌ General Error: $e');
      setState(() {
        _errorMessage = 'Có lỗi xảy ra với đăng nhập Microsoft. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Xử lý sau khi đăng nhập thành công
  Future<void> _handleSuccessfulLogin(User user) async {
    print('🔄 Syncing with Firestore...');

    // Trích xuất studentId từ email
    final studentId = UserService.extractStudentId(user.email);

    if (studentId.isEmpty) {
      setState(() {
        _errorMessage = 'Email không chứa mã sinh viên hợp lệ (cần 9 chữ số). Vui lòng sử dụng email sinh viên.';
      });
      await _auth.signOut();
      return;
    }

    print('🎓 Student ID extracted: $studentId');

    final role = await UserService.syncUserAndGetRole(user);

    if (role == null || role.isEmpty) {
      setState(() {
        _errorMessage = 'Không thể xác định vai trò. Vui lòng thử lại.';
      });
      await _auth.signOut();
      return;
    }

    print('✅ Role confirmed: $role');

    // Chuyển trang dựa trên role - SỬ DỤNG STUDENT ID thay vì UID
    if (mounted) {
      print('🚀 Navigating to $role panel');
      print('   Using Student ID: $studentId');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => role == 'student'
              ? ClassListPage(studentId: studentId)
              : const TeacherPanel(),
        ),
            (route) => false,
      );
    }
  }

  void _showDialog({required String title, required String message, required bool isError}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade100,
              Colors.white,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 80,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Student Quiz App',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đăng nhập bằng tài khoản Microsoft',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Card chứa nút đăng nhập
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Error message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Nút đăng nhập Microsoft
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handleMicrosoftLogin,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey, width: 1.5),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Microsoft Logo
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CustomPaint(
                                    painter: MicrosoftLogoPainter(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Đăng nhập với Microsoft',
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Info text
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sử dụng email sinh viên',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Email phải chứa 9 chữ số mã sinh viên',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 13,
                                  height: 1.4,
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
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Painter để vẽ logo Microsoft
class MicrosoftLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 2.2;
    final gap = size.width * 0.08;

    // Ô đỏ (trên trái)
    final redPaint = Paint()..color = const Color(0xFFF25022);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, squareSize, squareSize),
      redPaint,
    );

    // Ô xanh lá (trên phải)
    final greenPaint = Paint()..color = const Color(0xFF7FBA00);
    canvas.drawRect(
      Rect.fromLTWH(squareSize + gap, 0, squareSize, squareSize),
      greenPaint,
    );

    // Ô xanh dương (dưới trái)
    final bluePaint = Paint()..color = const Color(0xFF00A4EF);
    canvas.drawRect(
      Rect.fromLTWH(0, squareSize + gap, squareSize, squareSize),
      bluePaint,
    );

    // Ô vàng (dưới phải)
    final yellowPaint = Paint()..color = const Color(0xFFFEB902);
    canvas.drawRect(
      Rect.fromLTWH(squareSize + gap, squareSize + gap, squareSize, squareSize),
      yellowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}