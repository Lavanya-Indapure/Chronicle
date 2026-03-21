import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract interface for authentication.
/// Decouples domain logic from data layer.
abstract class AuthRepository {
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    DateTime? dob,
  });

  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> resetPassword(String email);

  bool get isAuthenticated;
  User? get currentUser;
}
