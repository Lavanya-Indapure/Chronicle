import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/services/form_draft_store.dart';

/// Gives each signed-in user a fresh [ProviderScope].
///
/// Feature controllers are app-wide providers that load their data once, so
/// without this, signing out and in as someone else would keep showing the
/// previous user's data. When the user id from [userIds] changes, every
/// provider is thrown away and rebuilt for the new user, unsaved form drafts
/// are dropped, and [onSignedOut] runs when nobody is signed in any more.
class UserSessionScope extends StatefulWidget {
  /// The signed-in user's id each time the auth state changes (null when
  /// signed out). Repeats of the same id are ignored.
  final Stream<String?> userIds;

  /// The user signed in when the app starts, if any.
  final String? initialUserId;

  /// Runs after the user signs out (e.g. to cancel their reminders).
  final Future<void> Function()? onSignedOut;

  final Widget child;

  const UserSessionScope({
    super.key,
    required this.userIds,
    required this.initialUserId,
    required this.child,
    this.onSignedOut,
  });

  @override
  State<UserSessionScope> createState() => _UserSessionScopeState();
}

class _UserSessionScopeState extends State<UserSessionScope> {
  late String? _userId = widget.initialUserId;
  late final StreamSubscription<String?> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.userIds.listen(_onUser);
  }

  void _onUser(String? next) {
    if (next == _userId) return;
    FormDraftStore.clearAll();
    if (next == null) widget.onSignedOut?.call();
    setState(() => _userId = next);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(key: ValueKey(_userId), child: widget.child);
}
