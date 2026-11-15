// Shared harness for UI smoke tests: builds the app themes, renders a screen
// at a phone size inside the real nav bar, and optionally writes PNG
// snapshots for visual review.
//
// Snapshots: run with
//   flutter test <file> --update-goldens \
//     --dart-define=CAPTURE=true --dart-define=FONT_DIR=/path/to/poppins
// FONT_DIR is optional; it must hold Poppins-{Regular,Medium,SemiBold,Bold}.ttf
// so text renders as real glyphs instead of test boxes.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/providers/supabase_provider.dart';
import 'package:chronicle/core/theme/app_theme.dart';
import 'package:chronicle/core/widgets/floating_nav_bar.dart';

const captureSnapshots = bool.fromEnvironment('CAPTURE');
const snapshotFontDir = String.fromEnvironment('FONT_DIR');

/// Common phone sizes (logical pixels).
const smallPhone = Size(360, 800);
const largePhone = Size(412, 915);

/// Index of each tab in the floating nav bar.
abstract final class NavTab {
  static const dashboard = 0;
  static const todos = 1;
  static const expenses = 2;
  static const health = 3;
  static const more = 4;
}

class TestThemes {
  final ThemeData dark;
  final ThemeData light;

  const TestThemes(this.dark, this.light);

  Map<String, ThemeData> get all => {'dark': dark, 'light': light};
}

/// Call once at the top of a test file's `main()`.
///
/// google_fonts can't fetch Poppins in tests and reports that as an async
/// error, so the themes are built in a zone that swallows it.
TestThemes setUpUiTests() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late final ThemeData dark;
  late final ThemeData light;
  runZonedGuarded(() {
    dark = AppTheme.dark;
    light = AppTheme.light;
  }, (_, _) {});

  if (captureSnapshots && snapshotFontDir.isNotEmpty) {
    setUpAll(() => _loadSnapshotFonts(snapshotFontDir));
  }
  return TestThemes(dark, light);
}

const _navItems = [
  FloatingNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: AppStrings.dashboardLabel),
  FloatingNavItem(icon: Icons.check_circle_outline, selectedIcon: Icons.check_circle, label: AppStrings.todosLabel),
  FloatingNavItem(icon: Icons.bar_chart_rounded, selectedIcon: Icons.bar_chart_rounded, label: AppStrings.expensesLabel),
  FloatingNavItem(icon: Icons.favorite_outline, selectedIcon: Icons.favorite, label: AppStrings.healthLabel),
  FloatingNavItem(icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view_rounded, label: AppStrings.moreLabel),
];

/// Renders [screen] above the floating nav bar at [size] with [overrides]
/// (fake controllers etc.), then lets entry animations settle.
/// The signed-in user's first name is always faked as "Alex".
Future<void> pumpAppScreen(
  WidgetTester tester, {
  required Widget screen,
  required ThemeData theme,
  Size size = smallPhone,
  int navIndex = NavTab.more,
  List<Override> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserFirstNameProvider.overrideWithValue('Alex'),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(
          body: screen,
          bottomNavigationBar: FloatingNavBar(
            items: _navItems,
            selectedIndex: navIndex,
            onSelected: (_) {},
            onAction: () {},
            actionLabel: AppStrings.quickAdd,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

/// Writes `test/goldens/<name>.png` when running with CAPTURE=true.
Future<void> captureSnapshot(WidgetTester tester, String name) async {
  if (!captureSnapshots) return;
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

/// Loads real fonts so captured snapshots show readable text and icons.
Future<void> _loadSnapshotFonts(String fontDir) async {
  Future<ByteData> read(String path) async => ByteData.sublistView(await File(path).readAsBytes());

  // google_fonts asks for one family per weight, e.g. "Poppins_600".
  const weights = {'regular': 'Regular', '500': 'Medium', '600': 'SemiBold', '700': 'Bold'};
  for (final MapEntry(key: variant, value: file) in weights.entries) {
    await (FontLoader('Poppins_$variant')..addFont(read('$fontDir/Poppins-$file.ttf'))).load();
  }

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final icons = FontLoader('MaterialIcons')
      ..addFont(read('$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf'));
    await icons.load();
  }
}
