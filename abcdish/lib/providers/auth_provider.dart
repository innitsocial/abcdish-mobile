import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:abcdish/services/auth_service.dart';

const Object _unset = Object();

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
    Object? errorMessage = _unset,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.ref) : super(const AuthState(isLoggedIn: false));

  final Ref ref;
  final AuthService _authService = AuthService.instance;

  Future<void> checkLoginStatus() async {
    try {
      final loggedIn = await _authService.isLoggedIn();

      state = state.copyWith(
        isLoggedIn: loggedIn,
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      debugPrint('Auth bootstrap error: $error');
      state = state.copyWith(
        isLoggedIn: false,
        isLoading: false,
        errorMessage: null,
      );
    }
  }

  Future<bool> requestRegisterEmailOtp({
    required String name,
    required String email,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.requestRegisterEmailOtp(name: name, email: email);
      state = state.copyWith(isLoading: false, errorMessage: null);
      return true;
    } catch (error) {
      debugPrint('Register email OTP request error: $error');
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<bool> verifyRegisterEmailOtp({
    required String email,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.verifyRegisterEmailOtp(email: email, otp: otp);
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        errorMessage: null,
      );
      return true;
    } catch (error) {
      debugPrint('Register email OTP verify error: $error');
      state = state.copyWith(
        isLoggedIn: false,
        isLoading: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  Future<bool> requestEmailOtp(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.requestEmailOtp(email);
      state = state.copyWith(isLoading: false, errorMessage: null);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<bool> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.verifyEmailOtp(email: email, otp: otp);
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
    markLoggedOut();
  }

  void markLoggedOut() {
    state = state.copyWith(
      isLoggedIn: false,
      isLoading: false,
      errorMessage: null,
    );
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.deleteAccount();
      state = state.copyWith(
        isLoggedIn: false,
        isLoading: false,
        errorMessage: null,
      );
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
