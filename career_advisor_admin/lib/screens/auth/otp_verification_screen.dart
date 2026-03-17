import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../providers/app_auth_provider.dart';
import '../../utils/theme.dart';
import '../../services/token_service.dart';
import '../../widgets/animated_screen.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String? email;
  final bool isLogin;
  final bool isAdmin;
  const OtpVerificationScreen({
    super.key,
    this.email,
    this.isLogin = false,
    this.isAdmin = false,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _currentEmail() {
    final fromProp = widget.email?.trim() ?? '';
    if (fromProp.isNotEmpty) return fromProp;
    return _emailController.text.trim();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _sendOtp() async {
    if (_isLoading) return false;
    final email = _currentEmail();
    if (email.isEmpty) {
      setState(() {
        _error = 'Enter your registered email';
      });
      return false;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(apiServiceProvider).sendEmailVerificationOtp(email);
      if (!mounted) return false;
      setState(() {
        _info = 'OTP sent to $email';
        _isLoading = false;
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      String msg = 'Failed to send OTP';
      bool likelyRegistrationDelay = false;
      if (e is DioException) {
        final data = e.response?.data;
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          msg = 'Connection error. Check Settings > Server URL.';
        }
        if ((e.response?.statusCode ?? 0) >= 500) {
          msg = 'Server error while sending email. Check mail configuration.';
        }
        if (data is String && data.isNotEmpty) {
          msg = data;
          if (msg.toLowerCase().contains('not registered')) {
            likelyRegistrationDelay = true;
          }
        } else if (data is Map && data['message'] is String) {
          msg = data['message'] as String;
          final m = msg.toLowerCase();
          if (m.contains('not registered') || m.contains('not found')) {
            likelyRegistrationDelay = true;
          }
        } else if (e.response?.statusCode == 400) {
          likelyRegistrationDelay = true;
        }
      }
      setState(() {
        _error = msg;
        _isLoading = false;
        if (likelyRegistrationDelay) {
          _info = 'Setting up your account, retrying...';
        }
      });
      return false;
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    final email = _currentEmail();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your registered email');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _info = null;
    });
    try {
      if (widget.isLogin) {
        await ref
            .read(authServiceProvider)
            .verifyLoginOtp(
              email,
              _codeController.text.trim(),
              isAdmin: widget.isAdmin,
            );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification successful. Logged in!'),
            backgroundColor: Colors.green,
          ),
        );

        // Update global auth state
        await ref.read(appAuthProvider.notifier).checkAuth();

        if (!mounted) return;
        context.go('/dashboard');
        return;
      }

      final data = await ref
          .read(apiServiceProvider)
          .verifyEmailOtp(email, _codeController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified. Redirecting...'),
          backgroundColor: Colors.green,
        ),
      );
      try {
        final token = (data is Map && data['token'] is String)
            ? data['token'] as String
            : '';
        if (token.isNotEmpty) {
          await ref.read(tokenServiceProvider.notifier).saveUserAuth({
            'token': token,
          });
          final userMap = data is Map ? Map<String, dynamic>.from(data) : {};
          await ref
              .read(tokenServiceProvider.notifier)
              .saveUser(Map<String, dynamic>.from(userMap));
          if (!mounted) return;
          context.go('/dashboard');
          return;
        }
        // Fallback if server didn't return token: rely on session presence
        final hasSession = await ref
            .read(tokenServiceProvider.notifier)
            .hasUserSession();
        if (!mounted) return;
        context.go(hasSession ? '/dashboard' : '/login');
      } catch (_) {
        if (!mounted) return;
        context.go('/login');
      }
    } on DioException catch (e) {
      String msg = 'Invalid or expired OTP';
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        msg = data['message'] as String;
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      }
      if (mounted) {
        setState(() {
          _error = msg;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Invalid or expired OTP';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: AppTheme.gray50,
        appBar: AppBar(
          title: Text(
            widget.isLogin ? 'Two-Factor Auth' : 'Verify Email',
            style: const TextStyle(color: AppTheme.gray900),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.gray900),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isAdmin
                              ? [
                                  AppTheme.adminPrimaryRed,
                                  AppTheme.adminPrimaryOrange,
                                ]
                              : [
                                  AppTheme.userPrimaryBlue,
                                  AppTheme.userPrimaryPurple,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.isLogin ? 'Login Verification' : 'Verify Email',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if ((widget.email ?? '').isNotEmpty)
                    Text(
                      widget.email ?? '',
                      style: const TextStyle(
                        color: AppTheme.gray600,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Registered Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Enter your registered email';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(t)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_info != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _info!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'OTP Code',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.length != 6) return 'Enter 6 digits';
                      if (!RegExp(r'^\d{6}$').hasMatch(t)) return 'Digits only';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.userPrimaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Verify'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _sendOtp();
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Resend OTP'),
                  ),
                  // TextButton(
                  //   onPressed: _isLoading ? null : _showServerUrlDialog,
                  //   child: const Text(
                  //     'Server URL',
                  //     style: TextStyle(
                  //       color: AppTheme.userPrimaryBlue,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
