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

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
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
          .loginAdmin(email, password);

      if (mounted) {
        if (result is Map<String, dynamic> &&
            result['status'] == 'REQUIRES_OTP') {
          // Redirect to OTP verification screen with login mode and admin flag
          context.pushReplacement(
            Uri(
              path: '/verify-otp',
              queryParameters: {
                'email': email,
                'isLogin': 'true',
                'isAdmin': 'true',
              },
            ).toString(),
          );
          return;
        }

        // Update state to authenticated via appAuthProvider
        await ref.read(appAuthProvider.notifier).checkAuth();

        if (!mounted) return;
        context.go('/admin/dashboard');
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
              _error = 'Invalid admin credentials.';
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
            onPressed: () => context.go('/landing'),
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
                            AppTheme.adminPrimaryRed,
                            AppTheme.adminPrimaryOrange,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  const Text(
                    'Admin Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Access the administrative dashboard',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppTheme.gray600),
                  ),
                  const SizedBox(height: 32),
                  // Error message
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Admin Email',
                      hintText: 'Enter admin email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter password',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.adminPrimaryRed,
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
                        : const Text(
                            'Access Admin Dashboard',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  // // Demo credentials
                  // Container(
                  //   padding: const EdgeInsets.all(16),
                  //   decoration: BoxDecoration(
                  //     color: AppTheme.gray100,
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       const Text(
                  //         'Demo Credentials',
                  //         style: TextStyle(
                  //           fontWeight: FontWeight.bold,
                  //           color: AppTheme.gray900,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 8),
                  //       // const Text('Email: admin@careerpathai.com'),
                  //       // const Text('Password: admin123'),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 24),
                  // Back to main site
                  TextButton(
                    onPressed: () {
                      context.go('/landing');
                    },
                    child: const Text('Back to Main Site'),
                  ),
                  // User login link
                  TextButton(
                    onPressed: () {
                      context.pushReplacement('/login');
                    },
                    child: const Text('User Login'),
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
