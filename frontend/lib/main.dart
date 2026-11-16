import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_strings.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Local reminders (water, dues). Tapping one opens the screen it names.
  final notifications = NotificationService.instance;
  await notifications.init();
  notifications.onOpenRoute = AppRouter.router.go;

  runApp(
    const ProviderScope(
      child: ChronicleApp(),
    ),
  );

  final launchRoute = notifications.launchRoute;
  if (launchRoute != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) => AppRouter.router.go(launchRoute));
  }
}

class ChronicleApp extends ConsumerWidget {
  const ChronicleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
