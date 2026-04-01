import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_auth_provider.dart';
import '../utils/theme.dart';
import '../widgets/animated_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final minSplashTime = Future.delayed(const Duration(seconds: 2));

    try {
      await ref
          .read(appAuthProvider.notifier)
          .checkAuth()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Auth check error or timeout: $e');
    }

    await minSplashTime;

    if (!mounted) return;

    final status =
        ref.read(appAuthProvider).valueOrNull ?? AuthStatus.unauthenticated;

    if (status == AuthStatus.authenticatedAdmin) {
      context.go('/dashboard');
    } else {
      context.go('/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScreen(
      child: Scaffold(
        body: Container(
          decoration: AppTheme.getAdminGradient(),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/icons/app_logo1.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, _) {
                      return const Icon(
                        Icons.admin_panel_settings,
                        size: 48,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // App Name
                const Text(
                  'CareerPath Admin',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Manage Your CareerPath Ecosystem',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 48),
                // Loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
