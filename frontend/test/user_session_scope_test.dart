import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/services/form_draft_store.dart';
import 'package:chronicle/core/widgets/user_session_scope.dart';

class _Counter extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

final _counterProvider = NotifierProvider<_Counter, int>(_Counter.new);

class _CounterText extends ConsumerWidget {
  const _CounterText();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Text('count ${ref.watch(_counterProvider)}');
}

class _CounterApp extends ConsumerWidget {
  final GoRouter router;

  const _CounterApp(this.router);

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(routerConfig: router);
}

void main() {
  late StreamController<String?> users;
  late int signedOutCalls;
  late GoRouter router;

  setUp(() {
    users = StreamController<String?>();
    signedOutCalls = 0;
    FormDraftStore.clearAll();
    // Same shape as AppRouter: one long-lived router with a global navigator key.
    router = GoRouter(
      navigatorKey: GlobalKey<NavigatorState>(),
      routes: [GoRoute(path: '/', builder: (_, _) => const Scaffold(body: _CounterText()))],
    );
  });

  tearDown(() => users.close());

  Future<void> pumpScope(WidgetTester tester, {String? initialUserId = 'user-a'}) => tester.pumpWidget(
        UserSessionScope(
          userIds: users.stream,
          initialUserId: initialUserId,
          onSignedOut: () async => signedOutCalls++,
          child: _CounterApp(router),
        ),
      );

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(_CounterText)));

  testWidgets('a different user gets fresh provider state', (tester) async {
    await pumpScope(tester);
    containerOf(tester).read(_counterProvider.notifier).increment();
    await tester.pump();
    expect(find.text('count 1'), findsOneWidget);

    users.add('user-b');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('count 0'), findsOneWidget);
  });

  testWidgets('signing out resets state, drops drafts and runs onSignedOut', (tester) async {
    await pumpScope(tester);
    containerOf(tester).read(_counterProvider.notifier).increment();
    FormDraftStore.write('expense:new', {'amount': '500'});

    users.add(null);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('count 0'), findsOneWidget);
    expect(FormDraftStore.has('expense:new'), isFalse);
    expect(signedOutCalls, 1);
  });

  testWidgets('repeat events for the same user keep state', (tester) async {
    await pumpScope(tester);
    containerOf(tester).read(_counterProvider.notifier).increment();
    FormDraftStore.write('expense:new', {'amount': '500'});

    users.add('user-a'); // e.g. token refreshed
    await tester.pumpAndSettle();

    expect(find.text('count 1'), findsOneWidget);
    expect(FormDraftStore.has('expense:new'), isTrue);
    expect(signedOutCalls, 0);
  });
}
