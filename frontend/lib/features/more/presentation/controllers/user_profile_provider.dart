import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/providers/supabase_provider.dart';

/// Display details of the signed-in user, from Supabase auth + signup metadata.
class UserProfile {
  final String? firstName;
  final String? lastName;
  final String? email;
  final DateTime? memberSince;

  const UserProfile({this.firstName, this.lastName, this.email, this.memberSince});

  /// "Lavanya Indapure", or null when no name was given at signup.
  String? get fullName {
    final name = [firstName, lastName].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ').trim();
    return name.isEmpty ? null : name;
  }

  /// First letter for the avatar.
  String get initial {
    final source = fullName ?? email ?? '';
    return source.isEmpty ? '?' : source.characters.first.toUpperCase();
  }
}

final userProfileProvider = Provider<UserProfile?>((ref) {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  if (user == null) return null;
  final meta = user.userMetadata ?? const {};
  String? text(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
  return UserProfile(
    firstName: text(meta['first_name']),
    lastName: text(meta['last_name']),
    email: user.email,
    memberSince: DateTime.tryParse(user.createdAt),
  );
});
