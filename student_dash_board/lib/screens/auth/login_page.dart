// ============= FILE: lib/screens/auth/login_page.dart =============
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../student/student_panel.dart';
import '../teacher/teacher_panel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Xử lý đăng nhập Email/Password và đồng bộ với Firestore
  Future<void> _handleEmailPasswordLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔐 Attempting email/password login...');

      // Bước 1: Đăng nhập Firebase Authentication
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user == null) {
        throw Exception('Đăng nhập thất bại');
      }

      final user = userCredential.user!;
      print('✅ Authentication successful: ${user.uid}');

      // Bước 2: Đồng bộ với Firestore và lấy role
      await _handleSuccessfulLogin(user);

    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      print('❌ General Error: $e');
      setState(() {
        _errorMessage = 'Có lỗi xảy ra. Vui lòng thử lại sau.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

      // Tùy chọn: Thêm custom parameters nếu cần
      // microsoftProvider.setCustomParameters({
      //   'tenant': 'YOUR_TENANT_ID', // Nếu dùng Azure AD cụ thể
      //   'prompt': 'select_account', // Luôn hiện màn hình chọn account
      // });

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

  /// Xử lý sau khi đăng nhập thành công (dùng chung cho cả Email và Microsoft)
  Future<void> _handleSuccessfulLogin(User user) async {
    print('🔄 Syncing with Firestore...');
    final role = await UserService.syncUserAndGetRole(user);

    if (role == null || role.isEmpty) {
      setState(() {
        _errorMessage = 'Không thể xác định vai trò. Vui lòng thử lại.';
      });
      await _auth.signOut();
      return;
    }

    print('✅ Role confirmed: $role');

    // Chuyển trang dựa trên role
    if (mounted) {
      print('🚀 Navigating to $role panel');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => role == 'student'
              ? StudentPanel(studentId: user.uid)
              : const TeacherPanel(),
        ),
            (route) => false,
      );
    }
  }

  /// Xử lý lỗi Firebase Authentication
  void _handleAuthError(FirebaseAuthException e) {
    print('❌ Firebase Auth Error: ${e.code}');
    setState(() {
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'Không tìm thấy tài khoản với email này';
          break;
        case 'wrong-password':
          _errorMessage = 'Mật khẩu không đúng';
          break;
        case 'invalid-email':
          _errorMessage = 'Email không hợp lệ';
          break;
        case 'user-disabled':
          _errorMessage = 'Tài khoản đã bị vô hiệu hóa';
          break;
        case 'invalid-credential':
          _errorMessage = 'Email hoặc mật khẩu không đúng';
          break;
        case 'too-many-requests':
          _errorMessage = 'Quá nhiều lần thử. Vui lòng thử lại sau';
          break;
        default:
          _errorMessage = 'Đăng nhập thất bại: ${e.message}';
      }
    });
  }

  /// Quên mật khẩu
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showDialog(
        title: 'Thông báo',
        message: 'Vui lòng nhập email để đặt lại mật khẩu',
        isError: true,
      );
      return;
    }

    if (!email.contains('@')) {
      _showDialog(
        title: 'Thông báo',
        message: 'Email không hợp lệ',
        isError: true,
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        _showDialog(
          title: 'Thành công',
          message: 'Email đặt lại mật khẩu đã được gửi đến $email. Vui lòng kiểm tra hộp thư của bạn.',
          isError: false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Không tìm thấy tài khoản với email này';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        default:
          message = 'Không thể gửi email. Vui lòng thử lại';
      }
      _showDialog(title: 'Lỗi', message: message, isError: true);
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
              child: Form(
                key: _formKey,
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
                        size: 60,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Student Quiz App',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đăng nhập vào tài khoản của bạn',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),

                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Error message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'example@email.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                              if (!value.contains('@')) return 'Email không hợp lệ';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            obscureText: _obscurePassword,
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                              if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _handleForgotPassword,
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login button Email/Password
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleEmailPasswordLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : const Text(
                                'Đăng nhập',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Divider với text "HOẶC"
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'HOẶC',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Nút đăng nhập Microsoft
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _handleMicrosoftLogin,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey, width: 1.5),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Microsoft Logo (4 màu đặc trưng)
                                  Container(
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
                                      fontSize: 16,
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

                    const SizedBox(height: 24),

                    // Info text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hệ thống sẽ tự động đồng bộ tài khoản với Firestore',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
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
        ),
      ),
    );
  }
}

// Custom Painter để vẽ logo Microsoft (4 ô vuông màu đặc trưng)
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