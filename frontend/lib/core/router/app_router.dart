import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/core/widgets/app_shell.dart';
import 'package:chronicle/features/auth/presentation/screens/login_screen.dart';
import 'package:chronicle/features/auth/presentation/screens/signup_screen.dart';
import 'package:chronicle/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:chronicle/features/todos/presentation/screens/todos_screen.dart';
import 'package:chronicle/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:chronicle/features/more/presentation/screens/more_screen.dart';
import 'package:chronicle/features/more/presentation/screens/more_sub_screens.dart';
import 'package:chronicle/features/more/presentation/screens/account_screens.dart';
import 'package:chronicle/features/photos/presentation/screens/photos_screen.dart';
import 'package:chronicle/features/restaurants/presentation/screens/restaurants_screen.dart';
import 'package:chronicle/features/restaurants/presentation/screens/restaurant_details_screen.dart';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';
import 'package:chronicle/features/thoughts/presentation/screens/thoughts_screen.dart';
import 'package:chronicle/features/books/presentation/screens/books_screen.dart';
import 'package:chronicle/features/movies/presentation/screens/movies_screen.dart';
import 'package:chronicle/features/vision_board/presentation/screens/vision_board_screen.dart';
import 'package:chronicle/features/vision_board/presentation/screens/vision_goal_details_screen.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/features/health/presentation/screens/health_home_screen.dart';
import 'package:chronicle/features/health/presentation/screens/hydration_screen.dart';
import 'package:chronicle/features/health/presentation/screens/sleep_screen.dart';
import 'package:chronicle/features/health/presentation/screens/activity_screen.dart';
import 'package:chronicle/features/health/presentation/screens/health_settings_screen.dart';
import 'package:chronicle/features/learnings/presentation/screens/learnings_screen.dart';
import 'package:chronicle/features/first_times/presentation/screens/first_times_screen.dart';
import 'package:chronicle/features/moods/presentation/screens/mood_board_screen.dart';
import 'package:chronicle/features/places/presentation/screens/places_visited_screen.dart';

/// Chronicle — Declarative Router with auth guard + session handling
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Listens to auth state changes and triggers router refresh
  static final _authNotifier = _AuthNotifier();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/signup';

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/dashboard';

      return null;
    },
    routes: [
      // ── Auth (no bottom nav) ──
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // ── Main App (with bottom nav) ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/todos',
                builder: (context, state) => const TodosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const ExpensesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/health',
                builder: (context, state) => const HealthHomeScreen(),
                routes: [
                  GoRoute(path: 'hydration', builder: (context, state) => const HydrationScreen()),
                  GoRoute(path: 'sleep', builder: (context, state) => const SleepScreen()),
                  GoRoute(path: 'activity', builder: (context, state) => const ActivityScreen()),
                  GoRoute(path: 'settings', builder: (context, state) => const HealthSettingsScreen()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── More Sub-features (full-screen push, no bottom nav) ──
      GoRoute(path: '/more/photos', builder: (context, state) => const PhotosScreen()),
      GoRoute(path: '/more/restaurants', builder: (context, state) => const RestaurantsScreen()),
      GoRoute(
        path: '/more/restaurants/details',
        builder: (context, state) {
          final restaurant = state.extra as Restaurant;
          return RestaurantDetailsScreen(restaurant: restaurant);
        },
      ),
       GoRoute(path: '/more/thoughts', builder: (context, state) => const ThoughtsScreen()),
       GoRoute(path: '/more/books', builder: (context, state) => const BooksScreen()),
       GoRoute(path: '/more/movies', builder: (context, state) => const MoviesScreen()),
       GoRoute(
         path: '/more/vision-board', 
         builder: (context, state) => const VisionBoardScreen(),
         routes: [
           GoRoute(
             path: 'details', 
             builder: (context, state) => VisionGoalDetailsScreen(goal: state.extra as VisionGoal),
           ),
         ],
       ),
      GoRoute(path: '/more/life-lessons', builder: (context, state) => const LifeLessonsScreen()),
      GoRoute(path: '/more/learnings', builder: (context, state) => const LearningsScreen()),
      GoRoute(path: '/more/first-time', builder: (context, state) => const FirstTimeExperiencesScreen()),
      GoRoute(path: '/more/mood-board', builder: (context, state) => const MoodBoardScreen()),
      GoRoute(path: '/more/places-visited', builder: (context, state) => const PlacesVisitedScreen()),
      GoRoute(path: '/more/miscellaneous', builder: (context, state) => const MiscellaneousScreen()),
      GoRoute(path: '/more/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/more/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
}

/// A [ChangeNotifier] that listens to Supabase auth state changes
/// and notifies [GoRouter] to re-evaluate its redirect.
class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  _AuthNotifier() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
