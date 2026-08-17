import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/supabase_service.dart';

class AuthDialog extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AuthDialog({super.key, required this.onAuthenticated});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _emailController = TextEditingController(text: 'quocphungccq1911h@gmail.com');
  final _passwordController = TextEditingController();
  bool _isSignUpMode = false;
  bool _isLoading = false;
  bool _showPassword = false;
  String _errorMsg = '';

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
        widget.onAuthenticated();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _errorMsg = 'Đăng ký không thành công. Kiểm tra lại thông tin!');
      }
    } else {
      final res = await SupabaseService.signInWithEmail(email, password);
      setState(() => _isLoading = false);
      if (res?.user != null) {
        widget.onAuthenticated();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _errorMsg = 'Đăng nhập thất bại. Kiểm tra lại Email / Mật khẩu!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textMutedColor = isDark ? AppTheme.textMuted : const Color(0xFF334155);
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBg = isDark ? AppTheme.bgApp : const Color(0xFFF1F5F9);
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🔑', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      _isSignUpMode ? 'Đăng Ký Tài Khoản' : 'Đăng Nhập Supabase',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textMutedColor),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isSignUpMode
                  ? 'Tạo tài khoản mới để lưu trữ & đồng bộ đám mây vĩnh viễn.'
                  : 'Nhập thông tin tài khoản Supabase của bạn để đồng bộ.',
              style: TextStyle(fontSize: 12, color: textMutedColor),
            ),
            const SizedBox(height: 16),

            if (_errorMsg.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Text(
                  _errorMsg,
                  style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Email Input
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: textMutedColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Password Input
            TextField(
              controller: _passwordController,
              obscureText: !_showPassword,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                labelStyle: TextStyle(color: textMutedColor),
                suffixIcon: GestureDetector(
                  onTapDown: (_) => setState(() => _showPassword = true),
                  onTapUp: (_) => setState(() => _showPassword = false),
                  onTapCancel: () => setState(() => _showPassword = false),
                  child: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _showPassword
                          ? AppTheme.skyBlueAccent
                          : textMutedColor,
                    ),
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                ),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.skyBlueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isSignUpMode ? 'Đăng Ký Ngay' : 'Đăng Nhập',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Toggle Mode Button
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUpMode = !_isSignUpMode;
                    _errorMsg = '';
                  });
                },
                child: Text(
                  _isSignUpMode
                      ? 'Đã có tài khoản? Đăng nhập'
                      : 'Chưa có tài khoản? Đăng ký ngay',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.skyBlueAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
