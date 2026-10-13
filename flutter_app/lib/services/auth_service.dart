import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/user.dart';
import 'api_service.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.read(apiServiceProvider)),
);

class AuthResult {
  const AuthResult({required this.user, required this.token});
  final User user;
  final String token;
}

class AuthService {
  AuthService(this._api);

  final ApiService _api;

  Future<AuthResult> login(String email, String password) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null ||
        data['user'] is! Map<String, dynamic> ||
        data['token'] is! String) {
      throw const FormatException(
        'The server returned an invalid login response.',
      );
    }

    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(authTokenKey, token);
    await preferences.setString(authUserKey, jsonEncode(user.toJson()));
    return AuthResult(user: user, token: token);
  }

  Future<User?> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(authTokenKey);
    final storedUser = preferences.getString(authUserKey);
    if (token == null || storedUser == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(storedUser);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Stored user data is invalid.');
      }
      return User.fromJson(decoded);
    } on FormatException {
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(authTokenKey);
    await preferences.remove(authUserKey);
  }
}
