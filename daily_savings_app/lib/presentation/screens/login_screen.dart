import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/local_storage_service.dart';
import '../../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _rememberMe = true;
  bool _isSignUpMode = false;
  bool _isLoading = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    final creds = LocalStorageService.getSavedCredentials();
    _rememberMe = creds['remember'] as bool? ?? true;
    _emailController =
        TextEditingController(text: creds['email'] as String? ?? '');
    _passwordController =
        TextEditingController(text: creds['password'] as String? ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Vui lòng nhập đầy đủ Email và Mật khẩu');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    if (_isSignUpMode) {
      final res = await SupabaseService.signUpWithEmail(email, password);
      setState(() => _isLoading = false);
      if (res?.user != null) {
        await LocalStorageService.saveSavedCredentials(
            email, password, _rememberMe);
        widget.onLoginSuccess();
      } else {
        setState(
            () => _errorMsg = 'Đăng ký không thành công. Kiểm tra thông tin!');
      }
    } else {
      final res = await SupabaseService.signInWithEmail(email, password);
      setState(() => _isLoading = false);
      if (res?.user != null) {
        await LocalStorageService.saveSavedCredentials(
            email, password, _rememberMe);
        widget.onLoginSuccess();
      } else {
        setState(() =>
            _errorMsg = 'Đăng nhập thất bại. Kiểm tra lại Email / Mật khẩu!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(28.0),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Hero Icon & Title
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.skyBlueAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.skyBlueAccent.withOpacity(0.4)),
                    ),
                    child: const Center(
                      child: Text('💰', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Sổ Tiết Kiệm Daily',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    _isSignUpMode
                        ? 'Đăng ký tài khoản để đồng bộ dữ liệu Realtime'
                        : 'Đăng nhập tài khoản Supabase để tiếp tục',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMsg.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Text(
                        _errorMsg,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.redAccent),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Input Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: AppTheme.skyBlueAccent),
                      filled: true,
                      fillColor: AppTheme.bgApp,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.skyBlueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password Input Field
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppTheme.skyBlueAccent),
                      filled: true,
                      fillColor: AppTheme.bgApp,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.skyBlueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Remember Me Checkbox
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: AppTheme.skyBlueAccent,
                          checkColor: Colors.black,
                          side: const BorderSide(color: AppTheme.textMuted),
                          onChanged: (val) {
                            setState(() {
                              _rememberMe = val ?? true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: const Text(
                            'Ghi nhớ tài khoản & mật khẩu',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Primary Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.skyBlueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isSignUpMode ? 'Tạo Tài Khoản Mới' : 'Đăng Nhập Ngay',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Toggle Sign In / Sign Up Mode
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUpMode = !_isSignUpMode;
                        _errorMsg = '';
                      });
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _isSignUpMode
                            ? 'Đã có tài khoản? Đăng nhập ngay'
                            : 'Chưa có tài khoản? Đăng ký tài khoản mới',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.skyBlueAccent,
                        ),
                      ),
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
