import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
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
              _error = 'Invalid email or password.';
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
                    'https://careerpathadvisorapplication-production.up.railway.app',
                helperText:
                    'Production: https://careerpathadvisorapplication-production.up.railway.app\nLocal: http://10.0.2.2:8080 or http://192.168.x.x:8080',
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
    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: AppTheme.gray50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.gray900),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: AppTheme.gray900),
              tooltip: 'Server Settings',
              onPressed: _showServerUrlDialog,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.userPrimaryBlue,
                            AppTheme.userPrimaryPurple,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue to CareerPath AI',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppTheme.gray600),
                  ),
                  const SizedBox(height: 40),

                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                          if (_error!.contains('Connection timeout') ||
                              _error!.contains('Network error'))
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                left: 36.0,
                              ),
                              child: TextButton.icon(
                                onPressed: _showServerUrlDialog,
                                icon: const Icon(Icons.settings, size: 16),
                                label: const Text('Configure Server URL'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
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
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.userPrimaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account? ',
                        style: TextStyle(color: AppTheme.gray600),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/register');
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      context.push('/admin/login');
                    },
                    child: const Text(
                      'Admin Login',
                      style: TextStyle(color: AppTheme.gray500),
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
