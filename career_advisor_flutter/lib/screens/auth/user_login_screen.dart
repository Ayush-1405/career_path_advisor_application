import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:career_advisor_flutter/providers/app_auth_provider.dart';
import 'package:career_advisor_flutter/providers/base_url_provider.dart';
import 'package:career_advisor_flutter/services/auth_service.dart';
import 'package:career_advisor_flutter/utils/config.dart';
import 'package:career_advisor_flutter/utils/theme.dart';
import '../../widgets/animated_screen.dart';

class UserLoginScreen extends ConsumerStatefulWidget {
  const UserLoginScreen({super.key});

  @override
  ConsumerState<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends ConsumerState<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _passwordError = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Use the authService directly to check for REQUIRES_OTP
      final result = await ref
          .read(authServiceProvider)
          .loginUser(email, password);

      if (mounted) {
        if (result is Map<String, dynamic> &&
            result['status'] == 'REQUIRES_OTP') {
          // Redirect to OTP verification screen with login mode
          context.pushReplacement(
            Uri(
              path: '/verify-otp',
              queryParameters: {'email': email, 'isLogin': 'true'},
            ).toString(),
          );
          return;
        }

        // Update state to authenticated via appAuthProvider
        await ref.read(appAuthProvider.notifier).checkAuth();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is DioException) {
            final url = e.requestOptions.uri.toString();
            if (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.connectionError) {
              _error = 'Connection error to $url. Check Settings.';
            } else if (e.response?.statusCode == 401) {
              _passwordError = 'Invalid email or password.';
            } else if (e.response?.statusCode == 404) {
              _error = 'Endpoint not found (404) at $url. Check Settings.';
            } else if (e.response != null) {
              _error =
                  e.response?.data?['message'] ??
                  'Server error (${e.response?.statusCode}) at $url';
            } else {
              _error = 'Network error at $url. Please try again.';
            }
          } else {
            _error = e.toString().replaceAll('Exception: ', '');
          }
          _isLoading = false;
        });
      }
    }
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
                // Strip trailing slash to avoid double slashes in paths
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : AppTheme.gray700,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/feed');
              }
            },
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
                              color: AppTheme.userPrimaryBlue.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white
                            : Color(0xFF0F172A), // Slate 900
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue to CareerPath AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? Colors.white70
                            : Color(0xFF64748B), // Slate 500
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : Color(0xFF64748B),
                        ),
                        hintText: 'Enter your registered email',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Color(0xFF94A3B8),
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: isDark ? Colors.white70 : Color(0xFF64748B),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC), // Slate 50
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Color(0xFFE2E8F0),
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

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : Color(0xFF64748B),
                        ),
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Color(0xFF94A3B8),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: isDark ? Colors.white70 : Color(0xFF64748B),
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: isDark ? Colors.white70 : Color(0xFF64748B),
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
                            color: isDark ? Colors.white12 : Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.userPrimaryBlue,
                            width: 2,
                          ),
                        ),
                        errorText: _passwordError,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) {
                        if (_passwordError != null) {
                          setState(() {
                            _passwordError = null;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          context.push('/forgot-password');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.userPrimaryBlue,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message
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
                                          : Color(0xFFB91C1C), // Red 700
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
                                //     tapTargetSize:
                                //         MaterialTapTargetSize.shrinkWrap,
                                //   ),
                                // ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Sign In Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
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
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),

                    // Don't have an account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.push('/register');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.userPrimaryBlue,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // TextButton(
                    //   onPressed: () => _showServerUrlDialog(),
                    //   child: const Text(
                    //     'Change Server URL',
                    //     style: TextStyle(
                    //       color: Color(0xFF64748B),
                    //       fontSize: 12,
                    //     ),
                    //   ),
                    // ),
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
