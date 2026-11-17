import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronicle/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chronicle/features/auth/domain/repositories/auth_repository.dart';
import 'package:chronicle/core/errors/app_exception.dart';

// ── Auth State ──
enum AuthStatus { initial, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({this.status = AuthStatus.initial, this.errorMessage});

  AuthState copyWith({AuthStatus? status, String? errorMessage}) => AuthState(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );
}

// ── Providers (DI) ──
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = Supabase.instance.client;
  final datasource = AuthRemoteDatasource(client);
  return AuthRepositoryImpl(datasource);
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

// ── Controller (Riverpod v3 Notifier) ──
class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    return const AuthState();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.signIn(email: email, password: password);
      state = state.copyWith(status: AuthStatus.success);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    DateTime? dob,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        dob: dob,
      );
      state = state.copyWith(status: AuthStatus.success);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    // Signing out replaces the whole ProviderScope (UserSessionScope), so
    // this controller may already be disposed.
    if (ref.mounted) state = const AuthState();
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.resetPassword(email);
      state = state.copyWith(status: AuthStatus.success);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      return false;
    }
  }

  void resetState() {
    state = const AuthState();
  }
}
