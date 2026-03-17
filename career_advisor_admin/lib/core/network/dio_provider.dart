import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../services/token_service.dart';
import '../../providers/base_url_provider.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final baseUrl = ref.watch(baseUrlProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('--- API Request: ${options.method} ${options.uri} ---');
        // Use admin token for /api/admin/* or when explicitly set
        final path = options.path.startsWith('/')
            ? options.path
            : '/${options.path}';
        final isAdmin =
            options.extra['isAdmin'] == true || path.startsWith('/api/admin');
        final tokenService = ref.read(tokenServiceProvider.notifier);

        String? token;
        if (isAdmin) {
          token = await tokenService.getAdminToken();
        } else {
          token = await tokenService.getUserToken();
        }

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint(
          '--- API Response: ${response.statusCode} ${response.requestOptions.uri} ---',
        );
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        debugPrint(
          '--- API Error: ${e.response?.statusCode} ${e.requestOptions.uri} ---',
        );
        if (e.response?.data != null) {
          debugPrint('--- API Error Response: ${e.response?.data} ---');
        }
        if (e.response?.statusCode == 401) {
          final tokenService = ref.read(tokenServiceProvider.notifier);
          final path = e.requestOptions.path.startsWith('/')
              ? e.requestOptions.path
              : '/${e.requestOptions.path}';
          final isAdmin =
              e.requestOptions.extra['isAdmin'] == true ||
              path.startsWith('/api/admin');
          if (isAdmin) {
            await tokenService.clearAdminAuth();
          } else {
            await tokenService.clearUserAuth();
          }
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
}
