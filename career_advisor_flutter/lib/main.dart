import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/base_url_provider.dart';
import 'router/app_router.dart';
import 'utils/theme.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedUrl = prefs.getString('api_base_url');

  // Logic to handle URL overrides safely
  String? urlOverride;
  if (savedUrl != null && savedUrl.startsWith('http')) {
    // In release mode, ignore local overrides (localhost/10.0.2.2/192.168.x.x etc)
    // to prevent connection errors on real devices from old debug session settings
    const bool isRelease = bool.fromEnvironment('dart.vm.product');
    final bool isLocal =
        savedUrl.contains('localhost') ||
        savedUrl.contains('10.') ||
        savedUrl.contains('127.0.0.1') ||
        savedUrl.contains('192.168.') ||
        savedUrl.contains('172.'); // Common local IP ranges

    if (!isRelease || !isLocal) {
      urlOverride = savedUrl;
      // Ensure no trailing slash to avoid // in URL
      if (urlOverride.endsWith('/')) {
        urlOverride = urlOverride.substring(0, urlOverride.length - 1);
      }
    } else {
      debugPrint('Release mode: Ignoring local API override $savedUrl');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        if (urlOverride != null)
          baseUrlProvider.overrideWith((ref) => urlOverride!),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'CareerPath AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getUserTheme(isDark: false),
      darkTheme: AppTheme.getUserTheme(isDark: true),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (widget, animation) =>
              FadeTransition(opacity: animation, child: widget),
          child: child,
        );
      },
    );
  }
}
