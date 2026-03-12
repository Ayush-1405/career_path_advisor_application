import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/app_roles.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import 'api_service.dart';
import 'token_service.dart';

part 'auth_service.g.dart';

@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  final tokenService = ref.watch(tokenServiceProvider.notifier);
  return AuthService(apiService, tokenService);
}

class AuthService {
  final ApiService _apiService;
  final TokenService _tokenService;

  AuthService(this._apiService, this._tokenService);

  // User login
  Future<dynamic> loginUser(String email, String password) async {
    try {
      final response = await _apiService.loginUser(email, password);

      if (response['status'] == 'REQUIRES_OTP') {
        return response; // Return the full response for UI to handle
      }

      if (response['token'] == null) {
        throw Exception('Invalid response from server');
      }

      final authResponse = AuthResponse.fromJson(response);

      // Store auth data
      await _storeAuth(authResponse, isAdmin: false);

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  // Admin login
  Future<dynamic> loginAdmin(String email, String password) async {
    try {
      final response = await _apiService.loginUser(email, password);

      if (response['status'] == 'REQUIRES_OTP') {
        return response;
      }

      if (response['token'] == null) {
        throw Exception('Invalid response from server');
      }

      // Validate admin role (must match backend)
      final role = response['role']?.toString() ?? '';
      if (!AppRoles.isAdmin(role)) {
        throw Exception('Access denied. Admin privileges required.');
      }

      final authResponse = AuthResponse.fromJson(response);

      // Store admin auth data
      await _storeAuth(authResponse, isAdmin: true);

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  // Verify login OTP
  Future<AuthResponse> verifyLoginOtp(
    String email,
    String code, {
    bool isAdmin = false,
  }) async {
    try {
      final response = await _apiService.verifyLoginOtp(email, code);

      if (response['token'] == null) {
        throw Exception('Verification failed');
      }

      final authResponse = AuthResponse.fromJson(response);

      // Store auth data
      await _storeAuth(authResponse, isAdmin: isAdmin);

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  // Register user
  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.registerUser({
        'name': name,
        'email': email,
        'password': password,
      });

      // Backend now returns Map with success: true and message: "Registered"
      if (response is Map) {
        return response['success'] == true ||
            response['message'] == 'Registered';
      }
      return response == 'Registered' ||
          response.toString().contains('Registered');
    } catch (e) {
      rethrow;
    }
  }

  // Password Reset
  Future<void> requestPasswordReset(
    String email,
    String redirectBaseUrl,
  ) async {
    await _apiService.forgotPassword(email, redirectBaseUrl);
  }

  Future<void> validateResetToken(String token, String email) async {
    await _apiService.validateResetToken(token, email);
  }

  Future<void> resetPassword(
    String token,
    String email,
    String newPassword,
  ) async {
    await _apiService.resetPassword(token, email, newPassword);
  }

  // Logout
  Future<void> logout() async {
    await _tokenService.clearUserAuth();
  }

  Future<void> logoutAdmin() async {
    await _tokenService.clearAdminAuth();
  }

  Future<User?> getCurrentAdmin() async {
    final adminData = await _tokenService.getAdminUser();
    if (adminData != null) {
      return User.fromJson(adminData);
    }
    return null;
  }

  // Get Current User
  Future<User?> getCurrentUser() async {
    final userData = await _tokenService.getUser();
    if (userData != null) {
      return User.fromJson(userData);
    }
    return null;
  }

  // Store authentication data
  Future<void> _storeAuth(
    AuthResponse authResponse, {
    required bool isAdmin,
  }) async {
    if (isAdmin) {
      final adminAuth = {
        'user': authResponse.user.toJson(),
        'token': authResponse.token,
      };
      await _tokenService.saveAdminAuth(adminAuth);
    } else {
      final auth = {'token': authResponse.token};
      await _tokenService.saveUserAuth(auth);
      await _tokenService.saveUser(authResponse.user.toJson());
    }
  }
}
