import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_auth_provider.g.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticatedUser,
  authenticatedAdmin,
}

@Riverpod(keepAlive: true)
class AppAuth extends _$AppAuth {
  @override
  Future<AuthStatus> build() async {
    final tokenService = ref.read(tokenServiceProvider.notifier);

    final sub = tokenService.onAuthChange.listen((_) {
      Future.microtask(() => ref.invalidateSelf());
    });
    ref.onDispose(sub.cancel);

    final adminToken = await tokenService.getAdminToken();
    if (adminToken != null) {
      return AuthStatus.authenticatedAdmin;
    }

    final userToken = await tokenService.getUserToken();
    if (userToken != null) {
      return AuthStatus.authenticatedUser;
    }

    return AuthStatus.unauthenticated;
  }

  Future<void> logout() async {
    final tokenService = ref.read(tokenServiceProvider.notifier);
    await tokenService.clearUserAuth();
    await tokenService.clearAdminAuth();
    state = const AsyncValue.data(AuthStatus.unauthenticated);
  }

  Future<void> loginUser(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      return await ref.read(authServiceProvider).loginUser(email, password);
    });

    if (result.hasError) {
      state = AsyncValue.error(result.error!, result.stackTrace!);
      throw result.error!;
    }

    final data = result.value;
    if (data is Map<String, dynamic> && data['status'] == 'REQUIRES_OTP') {
      state = const AsyncValue.data(AuthStatus.unauthenticated);
      return;
    }

    state = const AsyncValue.data(AuthStatus.authenticatedUser);
  }

  Future<void> loginAdmin(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      return await ref.read(authServiceProvider).loginAdmin(email, password);
    });

    if (result.hasError) {
      state = AsyncValue.error(result.error!, result.stackTrace!);
      throw result.error!;
    }

    final data = result.value;
    if (data is Map<String, dynamic> && data['status'] == 'REQUIRES_OTP') {
      state = const AsyncValue.data(AuthStatus.unauthenticated);
      return;
    }

    state = const AsyncValue.data(AuthStatus.authenticatedAdmin);
  }

  Future<void> verifyLoginOtp(
    String email,
    String code, {
    bool isAdmin = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authServiceProvider)
          .verifyLoginOtp(email, code, isAdmin: isAdmin);
      return isAdmin
          ? AuthStatus.authenticatedAdmin
          : AuthStatus.authenticatedUser;
    });
  }

  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    return await ref
        .read(authServiceProvider)
        .registerUser(name: name, email: email, password: password);
  }

  Future<void> checkAuth() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

@Riverpod(keepAlive: true)
Future<User?> currentUser(CurrentUserRef ref) async {
  final authStatus = ref.watch(appAuthProvider);
  if (authStatus.value == AuthStatus.authenticatedUser) {
    return ref.read(authServiceProvider).getCurrentUser();
  }
  return null;
}
