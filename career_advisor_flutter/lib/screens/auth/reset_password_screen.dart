import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/base_url_provider.dart';
import '../../utils/config.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';
import '../../widgets/password_requirement_checklist.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? token;
  final String? email;

  const ResetPasswordScreen({super.key, this.token, this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isValidating = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;
  String? _success;
  bool _tokenValid = false;
  bool _showTokenInput = false;

  @override
  void initState() {
    super.initState();
    if (widget.token != null && widget.email != null) {
      _isValidating = true;
      _validateToken(widget.token!, widget.email!);
    } else {
      _showTokenInput = true;
      if (widget.email != null) {
        _emailController.text = widget.email!;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                    'http://172.20.10.2:8080',
                helperText:
                    'Local: http://172.20.10.2:8080\nFor Physical Device: Use computer LAN IP',
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

  Future<void> _validateToken(String token, String email) async {
    setState(() {
      _isValidating = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).validateResetToken(token, email);
      if (mounted) {
        setState(() {
          _tokenValid = true;
          _isValidating = false;
          _showTokenInput = false;
          // Store validated values if they came from input
          if (widget.token == null) {
            // No need to store, controllers have them
          }
        });
      }
    } catch (e) {
      String errorMessage = 'Invalid or expired reset token';
      if (e is DioException) {
        if (e.response?.data != null) {
          errorMessage = e.response!.data.toString();
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
      }

      if (mounted) {
        setState(() {
          _error = errorMessage;
          _isValidating = false;
          if (widget.token != null) {
            // If token was passed via args and failed, maybe allow manual entry?
            _showTokenInput = true;
            _emailController.text = widget.email ?? '';
            _tokenController.text = widget.token ?? '';
          }
        });
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final token = widget.token ?? _tokenController.text;
      final email = widget.email ?? _emailController.text;

      await ref
          .read(authServiceProvider)
          .resetPassword(token, email, _passwordController.text);

      if (mounted) {
        setState(() {
          _success = 'Password reset successfully! You can now log in.';
          _isLoading = false;
        });

        // Navigate to login after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.pushReplacement('/login');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidating) {
      return AnimatedScreen(
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
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
            'Reset Password',
            style: TextStyle(
              color: isDark
                  ? Colors.white
                  : const Color(0xFF0F172A), // Slate 900
              fontWeight: FontWeight.w600,
            ),
          ),
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
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.userPrimaryBlue,
                              AppTheme.userPrimaryPurple,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.userPrimaryBlue.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Reset Password',
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

                    Text(
                      _showTokenInput
                          ? 'Enter the code sent to your email'
                          : 'Enter your new password below',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF64748B), // Slate 500
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Success Message
                    if (_success != null) ...[
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
                                _success!,
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

                    if (_showTokenInput) ...[
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
                          labelText: 'Email Address',
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
                            borderSide: const BorderSide(
                              color: AppTheme.userPrimaryBlue,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        enabled: widget.email == null,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _tokenController,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Verification Token',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                          hintText: 'Enter the token from your email',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                          ),
                          prefixIcon: Icon(
                            Icons.vpn_key_outlined,
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
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.userPrimaryBlue,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the token';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Error message for Token Input
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
                                            : const Color(
                                                0xFFB91C1C,
                                              ), // Red 700
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

                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _validateToken(
                                    _tokenController.text,
                                    _emailController.text,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.userPrimaryBlue,
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
                                'Verify Code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ],

                    if (_tokenValid) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                          hintText: 'Enter new password',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
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
                            borderSide: const BorderSide(
                              color: AppTheme.userPrimaryBlue,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 8),

                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _passwordController,
                        builder: (context, value, _) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 24.0,
                              top: 8.0,
                            ),
                            child: PasswordRequirementChecklist(
                              password: value.text,
                            ),
                          );
                        },
                      ),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                          hintText: 'Confirm new password',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
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
                            borderSide: const BorderSide(
                              color: AppTheme.userPrimaryBlue,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Error message for Reset Password
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2), // Red 50
                            border: Border.all(
                              color: const Color(0xFFFECACA), // Red 200
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
                                      style: const TextStyle(
                                        color: Color(0xFFB91C1C), // Red 700
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
                                  child: TextButton.icon(
                                    onPressed: _showServerUrlDialog,
                                    icon: const Icon(Icons.settings, size: 16),
                                    label: const Text('Configure Server URL'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFB91C1C),
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.userPrimaryBlue,
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
                                'Reset Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => _showServerUrlDialog(),
                      child: const Text(
                        'Change Server URL',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
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
