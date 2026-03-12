import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/app_auth_provider.dart';

import '../screens/splash_screen.dart';
import '../screens/landing_page.dart';
import '../screens/auth/user_login_screen.dart';
import '../screens/auth/user_register_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';

import '../screens/user/user_dashboard_screen.dart';
import '../screens/user/user_profile_screen.dart';
import '../screens/user/suggestions_screen.dart';
import '../screens/user/download_screen.dart';
import '../screens/user/analyze_screen.dart';
import '../screens/user/skills_screen.dart';
import '../screens/user/career_paths_screen.dart';
import '../screens/user/skills_assessment_screen.dart';
import '../screens/user/ai_assistant_screen.dart';
import '../screens/user/help_center_screen.dart';
import '../screens/user/contact_screen.dart';
import '../screens/user/privacy_policy_screen.dart';
import '../screens/user/terms_of_service_screen.dart';
import '../screens/user/my_resumes_screen.dart';
import '../screens/user/my_applications_screen.dart';
import '../screens/user/saved_careers_screen.dart';
import '../screens/user/resume_builder_screen.dart';

import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_analytics_screen.dart';
import '../screens/admin/admin_manage_screen.dart';
import '../screens/admin/admin_resumes_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/admin/admin_career_paths_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/admin/admin_applications_screen.dart';

import '../screens/user/home_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Wraps a route with a fade + slide transition for consistent navigation animations.
CustomTransitionPage<void> _buildAnimatedPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
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

      final isGuestRoute =
          location == '/landing' ||
          location == '/welcome' ||
          location == '/login' ||
          location == '/register' ||
          location == '/verify-otp' ||
          location == '/forgot-password' ||
          location == '/reset-password' ||
          location == '/admin/login';

      final isSharedRoute =
          location == '/privacy-policy' ||
          location == '/terms-of-service' ||
          location == '/help-center' ||
          location == '/contact';

      if (authStatus == AuthStatus.initial) {
        return null; // Let splash screen handle initialization
      }

      if (authStatus == AuthStatus.unauthenticated) {
        if (location == '/') return null; // Allow splash
        if (!isGuestRoute && !isSharedRoute) {
          return '/landing';
        }
        return null;
      }

      if (authStatus == AuthStatus.authenticatedUser) {
        if (isGuestRoute || location == '/') {
          return '/home';
        }
        if (location.startsWith('/admin')) {
          return '/home'; // Block user from admin pages
        }
        // Allow shared routes and other user routes
      }

      if (authStatus == AuthStatus.authenticatedAdmin) {
        if (isGuestRoute || location == '/' || !location.startsWith('/admin')) {
          // Allow shared routes for admin?
          // Admins might need to see terms/privacy/help too, but usually they stay in /admin
          // For now, let's keep admins in admin dashboard unless they explicitly go to shared routes?
          // Existing logic forced them to /admin/dashboard if !location.startsWith('/admin').
          // Let's stick to existing admin logic mostly, but maybe allow shared routes?
          if (isSharedRoute) return null;
          return '/admin/dashboard';
        }
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
        path: '/welcome',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const LandingPage()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const UserLoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const UserRegisterScreen()),
      ),
      GoRoute(
        path: '/verify-otp',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'];
          final isLogin = state.uri.queryParameters['isLogin'] == 'true';
          final isAdmin = state.uri.queryParameters['isAdmin'] == 'true';
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
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'];
          final email = state.uri.queryParameters['email'];
          return _buildAnimatedPage(
            state,
            ResetPasswordScreen(token: token, email: email),
          );
        },
      ),

      // User Routes
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const UserDashboardScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const UserProfileScreen()),
      ),
      GoRoute(
        path: '/suggestions',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const SuggestionsScreen()),
      ),
      GoRoute(
        path: '/download',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const DownloadScreen()),
      ),
      GoRoute(
        path: '/analyze',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AnalyzeScreen()),
      ),
      GoRoute(
        path: '/skills',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const SkillsScreen()),
      ),
      GoRoute(
        path: '/career-paths',
        pageBuilder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return _buildAnimatedPage(
            state,
            CareerPathsScreen(initialId: id),
          );
        },
      ),
      GoRoute(
        name: 'saved_careers',
        path: '/user/saved-careers',
        pageBuilder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final initialIndex = tab == '1' ? 1 : 0;
          return _buildAnimatedPage(
            state,
            SavedCareersScreen(initialIndex: initialIndex),
          );
        },
      ),
      GoRoute(
        path: '/skills-assessment',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const SkillsAssessmentScreen()),
      ),
      GoRoute(
        path: '/resume-builder',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const ResumeBuilderScreen()),
      ),
      GoRoute(
        path: '/ai-assistant',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AiAssistantScreen()),
      ),
      GoRoute(
        path: '/help-center',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const HelpCenterScreen()),
      ),
      GoRoute(
        path: '/contact',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const ContactScreen()),
      ),
      GoRoute(
        path: '/privacy-policy',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const PrivacyPolicyScreen()),
      ),
      GoRoute(
        path: '/terms-of-service',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const TermsOfServiceScreen()),
      ),
      GoRoute(
        path: '/my-resumes',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const MyResumesScreen()),
      ),
      GoRoute(
        path: '/my-applications',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const MyApplicationsScreen()),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/login',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminLoginScreen()),
      ),
      GoRoute(
        path: '/admin/dashboard',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminDashboardScreen()),
      ),
      GoRoute(
        path: '/admin/analytics',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminAnalyticsScreen()),
      ),
      GoRoute(
        path: '/admin/users',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminManageScreen()),
      ),
      GoRoute(
        path: '/admin/resumes',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminResumesScreen()),
      ),
      GoRoute(
        path: '/admin/settings',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminSettingsScreen()),
      ),
      GoRoute(
        path: '/admin/career-paths',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminCareerPathsScreen()),
      ),
      GoRoute(
        path: '/admin/reports',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminReportsScreen()),
      ),
      GoRoute(
        path: '/admin/applications',
        pageBuilder: (context, state) =>
            _buildAnimatedPage(state, const AdminApplicationsScreen()),
      ),
    ],
  );
});
