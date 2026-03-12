import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/base_url_provider.dart';
import 'router/app_router.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  String? savedUrl = prefs.getString('api_base_url');

  // If the saved URL is a local IP or an old production URL, clear it to favor the new one
  if (savedUrl != null &&
      (savedUrl.contains('10.0.2.2') ||
          savedUrl.contains('172.20.10.2') ||
          savedUrl.contains('localhost') ||
          savedUrl.contains('careeradvisoraiapplication'))) {
    await prefs.remove('api_base_url');
    savedUrl = null;
  }

  runApp(
    ProviderScope(
      overrides: [
        if (savedUrl != null && savedUrl.startsWith('http'))
          baseUrlProvider.overrideWith((ref) => savedUrl!),
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

    return MaterialApp.router(
      title: 'CareerPath AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getUserTheme(),
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
