import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// The signed-in user's first name from their signup metadata, if any.
final currentUserFirstNameProvider = Provider<String?>((ref) {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  final name = user?.userMetadata?['first_name'];
  return name is String && name.trim().isNotEmpty ? name.trim() : null;
});
