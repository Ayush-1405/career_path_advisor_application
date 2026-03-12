import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';

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
    // We don't watch tokenServiceProvider because it doesn't emit state changes for auth
    // Instead we rely on manual invalidation or checking shared preferences
    final tokenService = ref.read(tokenServiceProvider.notifier);

    // Listen to token service changes (e.g. logout triggered by 401)
    final sub = tokenService.onAuthChange.listen((_) {
      // Invalidate self to re-run build() and check tokens again
      // Use Future.microtask to avoid "modify while building" error
      Future.microtask(() => ref.invalidateSelf());
    });
    ref.onDispose(sub.cancel);

    // Check admin first (priority?) or just check both
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
      return; // UI will handle redirection based on the returned value from loginUser call if it was a direct call, but here we might need to handle it differently or return the status.
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
    if (state.hasError) {
      throw state.error!;
    }
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
