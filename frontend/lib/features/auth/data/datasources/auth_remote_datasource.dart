import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/core/constants/app_constants.dart';

/// Remote datasource — all Supabase Auth API calls live here.
/// No business logic, just API contracts.
class AuthRemoteDatasource {
  final SupabaseClient _client;

  AuthRemoteDatasource(this._client);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    // Mobile: deep link back into the app. Web: the Site URL (the web app
    // itself), where the recovery session is picked up from the URL.
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : AppConstants.passwordResetRedirect,
    );
  }

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
