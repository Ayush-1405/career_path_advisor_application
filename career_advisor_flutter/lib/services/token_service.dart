import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'token_service.g.dart';

@Riverpod(keepAlive: true)
class TokenService extends _$TokenService {
  final _storage = const FlutterSecureStorage();
  final _authStreamController = StreamController<void>.broadcast();

  Stream<void> get onAuthChange => _authStreamController.stream;

  @override
  FutureOr<void> build() {
    ref.onDispose(() {
      _authStreamController.close();
    });
  }

  Future<String?> getUserToken() async {
    final authData = await _storage.read(key: 'auth');
    if (authData != null) {
      final auth = jsonDecode(authData);
      return auth['token'];
    }
    return null;
  }

  Future<String?> getAdminToken() async {
    final adminAuthData = await _storage.read(key: 'adminAuth');
    if (adminAuthData != null) {
      final adminAuth = jsonDecode(adminAuthData);
      return adminAuth['token'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> getAdminUser() async {
    final adminAuthData = await _storage.read(key: 'adminAuth');
    if (adminAuthData != null) {
      final adminAuth = jsonDecode(adminAuthData);
      final user = adminAuth['user'];
      if (user is Map<String, dynamic>) {
        return user;
      }
    }
    return null;
  }

  Future<void> saveUserAuth(Map<String, dynamic> data) async {
    await _storage.write(key: 'auth', value: jsonEncode(data));
    _authStreamController.add(null);
  }

  Future<void> saveAdminAuth(Map<String, dynamic> data) async {
    await _storage.write(key: 'adminAuth', value: jsonEncode(data));
    _authStreamController.add(null);
  }

  // User object management - keep in SharedPreferences as it is not sensitive
  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }

  Future<void> clearUserAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await _storage.delete(key: 'auth');
    await prefs.remove('user');
    _authStreamController.add(null);
  }

  Future<void> clearAdminAuth() async {
    await _storage.delete(key: 'adminAuth');
    _authStreamController.add(null);
  }

  Future<bool> hasUserSession() async {
    return await getUserToken() != null;
  }

  Future<bool> hasAdminSession() async {
    return await getAdminToken() != null;
  }
}
