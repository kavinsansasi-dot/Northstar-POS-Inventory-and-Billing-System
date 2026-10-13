import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.error});

  final AuthStatus status;
  final User? user;
  final String? error;

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.unauthenticated({String? error}) =>
      AuthState(status: AuthStatus.unauthenticated, error: error);
  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    ApiService.onUnauthorized = () {
      state = AuthState.unauthenticated(
        error: 'Your session expired. Sign in again.',
      );
    };
    ref.onDispose(() => ApiService.onUnauthorized = null);
    scheduleMicrotask(_restore);
    return AuthState.loading();
  }

  Future<void> _restore() async {
    try {
      final user = await ref.read(authServiceProvider).restoreSession();
      state = user == null
          ? AuthState.unauthenticated()
          : AuthState.authenticated(user);
    } catch (error) {
      state = AuthState.unauthenticated(error: ApiService.errorMessage(error));
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final result = await ref.read(authServiceProvider).login(email, password);
      state = AuthState.authenticated(result.user);
      return true;
    } catch (error) {
      state = AuthState.unauthenticated(error: ApiService.errorMessage(error));
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = AuthState.unauthenticated();
  }
}
