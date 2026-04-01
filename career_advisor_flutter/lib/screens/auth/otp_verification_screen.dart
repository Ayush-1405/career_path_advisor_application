import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:career_advisor_flutter/services/api_service.dart';
import 'package:career_advisor_flutter/services/auth_service.dart';
import 'package:career_advisor_flutter/providers/app_auth_provider.dart';
import 'package:career_advisor_flutter/providers/base_url_provider.dart';
import 'package:career_advisor_flutter/utils/config.dart';
import 'package:career_advisor_flutter/utils/theme.dart';
import 'package:career_advisor_flutter/services/token_service.dart';
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
  final bool _initialOtpSent = false;

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showServerUrlDialog() {
    final currentUrl = ref.read(baseUrlProvider);
    final controller = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText:
                    'https://careerpathadvisorapplication-production.up.railway.app/',
                helperText:
                    'Production: https://careerpathadvisorapplication-production.up.railway.app/\nLocal: http://10.0.2.2:8080 or http://192.168.x.x:8080',
                helperMaxLines: 4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.text = AppConfig.baseUrl;
            },
            child: const Text('Reset to Default'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              String newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                if (newUrl.endsWith('/')) {
                  newUrl = newUrl.substring(0, newUrl.length - 1);
                }
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('api_base_url', newUrl);
                ref.read(baseUrlProvider.notifier).state = newUrl;
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
    FocusScope.of(context).unfocus();
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
        context.go(widget.isAdmin ? '/admin/dashboard' : '/dashboard');
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDarkerTheme = widget.isAdmin;
    final primaryColor = isDarkerTheme
        ? AppTheme.adminPrimaryRed
        : AppTheme.userPrimaryBlue;
    final gradientColors = isDarkerTheme
        ? [AppTheme.adminPrimaryRed, AppTheme.adminPrimaryOrange]
        : [AppTheme.userPrimaryBlue, AppTheme.userPrimaryPurple];

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(
            widget.isLogin ? 'Two-Factor Auth' : 'Verify Email',
            style: TextStyle(
              color: isDark
                  ? Colors.white
                  : const Color(0xFF0F172A), // Slate 900
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : const Color(0xFF0F172A).withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      widget.isLogin ? 'Login Verification' : 'Verify Email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0F172A), // Slate 900
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if ((widget.email ?? '').isNotEmpty)
                      Text(
                        widget.email ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF64748B), // Slate 500
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Registered Email',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                          hintText: 'Enter your registered email',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
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
                    const SizedBox(height: 32),

                    // Error Message
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.red.withOpacity(0.1)
                              : const Color(0xFFFEF2F2), // Red 50
                          border: Border.all(
                            color: isDark
                                ? Colors.red.withOpacity(0.2)
                                : const Color(0xFFFECACA), // Red 200
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFEF4444), // Red 500
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.redAccent
                                          : const Color(0xFFB91C1C), // Red 700
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_error!.contains('Connection timeout') ||
                                _error!.contains('Network error') ||
                                _error!.contains('Connection error') ||
                                _error!.contains('Endpoint not found'))
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 12.0,
                                  left: 32.0,
                                ),
                                // child: TextButton.icon(
                                //   onPressed: _showServerUrlDialog,
                                //   icon: const Icon(Icons.settings, size: 16),
                                //   label: const Text('Configure Server URL'),
                                //   style: TextButton.styleFrom(
                                //     foregroundColor: const Color(0xFFB91C1C),
                                //     padding: EdgeInsets.zero,
                                //     minimumSize: Size.zero,
                                //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                //   ),
                                // ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Info Message
                    if (_info != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.green.withOpacity(0.1)
                              : const Color(0xFFF0FDF4), // Green 50
                          border: Border.all(
                            color: isDark
                                ? Colors.green.withOpacity(0.2)
                                : const Color(0xFFBBF7D0), // Green 200
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Color(0xFF22C55E), // Green 500
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _info!,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.greenAccent
                                      : const Color(0xFF15803D), // Green 700
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // OTP Field
                    TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'Enter 6-digit Code',
                        labelStyle: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF64748B),
                          fontSize: 15,
                        ),
                        hintText: '------',
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFF94A3B8),
                          letterSpacing: 8,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20,
                        ),
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.length != 6) return 'Enter 6 digits';
                        if (!RegExp(r'^\d{6}$').hasMatch(t))
                          return 'Digits only';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Verify Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Resend OTP Button
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              _sendOtp();
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white70
                            : const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white12
                              : const Color(0xFFE2E8F0),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        context.pushReplacement('/login');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white38
                            : const Color(0xFF94A3B8),
                      ),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(fontSize: 14),
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
