import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/auth/presentation/screens/login_screen.dart';
import 'package:chronicle/features/auth/presentation/screens/signup_screen.dart';

/// Chronicle — Declarative Router with auth guard
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSignupRoute = state.matchedLocation == '/signup';

      if (isAuth && (isLoginRoute || isSignupRoute)) return '/dashboard';
      if (!isAuth && !isLoginRoute && !isSignupRoute) return '/login';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const _DashboardPlaceholder(),
      ),
    ],
  );
}

/// Temporary placeholder until Dashboard feature is built
class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Dashboard — Coming Soon',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
