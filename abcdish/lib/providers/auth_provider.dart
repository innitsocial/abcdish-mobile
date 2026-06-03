import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abcdish/services/auth_service.dart';
import 'package:flutter_riverpod/legacy.dart';

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
      errorMessage: errorMessage ?? this.errorMessage,
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
      debugPrint('REGISTER ERROR: $error');
      state = state.copyWith(
        isLoggedIn: false,
        isLoading: false,
        errorMessage: null,
      );
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.login(identifier: identifier, password: password);

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
    String? email,
    String? mobileNumber,
    String? password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.register(
        name: name,
        email: email,
        mobileNumber: mobileNumber,
        password: password,
      );

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

  Future<bool> requestMobileOtp(String mobileNumber) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.requestMobileOtp(mobileNumber);

      state = state.copyWith(isLoading: false, errorMessage: null);

      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());

      return false;
    }
  }

  Future<bool> verifyMobileOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.verifyMobileOtp(mobileNumber: mobileNumber, otp: otp);

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

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.forgotPassword(email);

      state = state.copyWith(isLoading: false, errorMessage: null);

      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());

      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      state = state.copyWith(isLoading: false, errorMessage: null);

      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());

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
  (ref) => AuthNotifier(ref),
);
