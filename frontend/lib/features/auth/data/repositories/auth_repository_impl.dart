import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronicle/features/auth/domain/repositories/auth_repository.dart';
import 'package:chronicle/core/errors/error_handler.dart';
import 'package:chronicle/core/services/logger_service.dart';

/// Concrete implementation of [AuthRepository].
/// Handles error mapping and logging.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    DateTime? dob,
  }) async {
    try {
      final metadata = {
        'first_name': firstName,
        'last_name': lastName,
        if (dob != null) 'dob': dob.toIso8601String().split('T').first,
      };
      await _datasource.signUp(
        email: email,
        password: password,
        metadata: metadata,
      );
      LoggerService.info('User signed up: $email', tag: 'Auth');
    } catch (e, st) {
      LoggerService.error('Sign up failed', error: e, stackTrace: st, tag: 'Auth');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _datasource.signIn(email: email, password: password);
      LoggerService.info('User signed in: $email', tag: 'Auth');
    } catch (e, st) {
      LoggerService.error('Sign in failed', error: e, stackTrace: st, tag: 'Auth');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _datasource.signOut();
      LoggerService.info('User signed out', tag: 'Auth');
    } catch (e, st) {
      LoggerService.error('Sign out failed', error: e, stackTrace: st, tag: 'Auth');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  bool get isAuthenticated => _datasource.currentSession != null;

  @override
  User? get currentUser => _datasource.currentUser;
}
