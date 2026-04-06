import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_auth_provider.dart';

import '../screens/splash_screen.dart';
import '../screens/landing_page.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_analytics_screen.dart';
import '../screens/admin/admin_manage_screen.dart';
import '../screens/admin/admin_resumes_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/admin/admin_career_paths_screen.dart';
import '../screens/admin/add_career_path_screen.dart';
import '../screens/admin/edit_career_path_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../models/career_path.dart';
import '../screens/admin/admin_applications_screen.dart';
import '../screens/admin/admin_social_screen.dart';
final _rootNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _buildAnimatedPage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
      );
    },
  );
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthStatus>(AuthStatus.initial);

  ref.listen(appAuthProvider, (_, next) {
    authNotifier.value = next.valueOrNull ?? AuthStatus.initial;
  }, fireImmediately: true);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authStatus = authNotifier.value;
      final location = state.uri.path;

      if (authStatus == AuthStatus.initial) {
        return null;
      }

      final isGuestRoute =
          location == '/landing' ||
          location == '/login' ||
          location == '/verify-otp';

      if (authStatus == AuthStatus.unauthenticated) {
        if (location == '/') return null; // Allow splash
        if (!isGuestRoute) return '/landing';
        return null;
      }

      if (authStatus == AuthStatus.authenticatedAdmin) {
        if (isGuestRoute || location == '/') return '/dashboard';
        return null;
      }

      // If for some reason a user token is used, treat as unauthenticated for admin app
      if (authStatus == AuthStatus.authenticatedUser) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/landing',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const LandingPage()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminLoginScreen()),
      ),
      GoRoute(
        path: '/verify-otp',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'];
          final isLogin = state.uri.queryParameters['isLogin'] == 'true';
          final isAdmin = true; // Always admin for this app
          return _buildAnimatedPage(
            state,
            OtpVerificationScreen(
              email: email,
              isLogin: isLogin,
              isAdmin: isAdmin,
            ),
          );
        },
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminDashboardScreen()),
      ),
      GoRoute(
        path: '/analytics',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminAnalyticsScreen()),
      ),
      GoRoute(
        path: '/users',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminManageScreen()),
      ),
      GoRoute(
        path: '/resumes',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminResumesScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminSettingsScreen()),
      ),
      GoRoute(
        path: '/career-paths',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminCareerPathsScreen()),
        routes: [
          GoRoute(
            path: 'add',
            pageBuilder: (context, state) =>
                _buildAnimatedPage(state, const AddCareerPathScreen()),
          ),
          GoRoute(
            path: 'edit',
            pageBuilder: (context, state) {
              final path = state.extra as CareerPath;
              return _buildAnimatedPage(
                state,
                EditCareerPathScreen(path: path),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminReportsScreen()),
      ),
      GoRoute(
        path: '/applications',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminApplicationsScreen()),
      ),
      GoRoute(
        path: '/social',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminSocialScreen()),
      ),
    ],
  );
});
