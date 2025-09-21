import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _err;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _pass,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_err != null)
              Text(_err!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      final ok = await auth.login(
                        _email.text.trim(),
                        _pass.text,
                      );
                      setState(() => _loading = false);
                      if (ok) {
                        Navigator.pop(context);
                      } else {
                        final errorMsg =
                            auth.errorMessage ??
                            'Email or password is incorrect';

                        // Show resend verification option if email not verified
                        if (errorMsg.contains('verify your email')) {
                          _showResendVerificationDialog();
                        } else {
                          // Only show error message for other errors (not email verification)
                          setState(() => _err = errorMsg);
                        }
                      }
                    },
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResendVerificationDialog() {
    // Clear any existing error message
    setState(() => _err = null);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Email has not been verified'),
          ],
        ),
        content: const Text(
          'Your account has not been verified. Would you like to resend the verification email?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resendVerification();
            },
            child: const Text('Resend'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendVerification() async {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập email và mật khẩu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final success = await auth.resendEmailVerification(
      _email.text.trim(),
      _pass.text,
    );

    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email xác thực đã được gửi lại. Vui lòng kiểm tra hộp thư của bạn.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Không thể gửi email xác thực'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
