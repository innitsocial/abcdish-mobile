import 'package:flutter_riverpod/legacy.dart';

import 'package:abcdish/services/auth_service.dart';

class AuthState {
  const AuthState({
    required this.isLoggedIn,
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isLoggedIn;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoggedIn: false)) {
    checkLoginStatus();
  }

  final AuthService _authService = AuthService.instance;

  Future<void> checkLoginStatus() async {
    final loggedIn = await _authService.isLoggedIn();

    state = state.copyWith(
      isLoggedIn: loggedIn,
      isLoading: false,
      errorMessage: null,
    );
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.login(email: email, password: password);

      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        errorMessage: null,
      );

      return true;
    } catch (error) {
      state = state.copyWith(
        isLoggedIn: false,
        isLoading: false,
        errorMessage: error.toString(),
      );

      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.register(name: name, email: email, password: password);

      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        errorMessage: null,
      );

      return true;
    } catch (error) {
      state = state.copyWith(
        isLoggedIn: false,
        isLoading: false,
        errorMessage: error.toString(),
      );

      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();

    state = state.copyWith(
      isLoggedIn: false,
      isLoading: false,
      errorMessage: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
