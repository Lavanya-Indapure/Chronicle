import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/auth/presentation/controllers/auth_controller.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moreLabel)),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          // ── Features Grid ──
          _buildSection(context, items: _featureItems),
          AppSpacing.gapLg,
          const Divider(),
          AppSpacing.gapSm,

          // ── Account ──
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text(AppStrings.profile),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text(AppStrings.settings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          AppSpacing.gapMd,
          FilledButton.tonal(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text(AppStrings.logout),
          ),
          AppSpacing.gapLg,
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required List<_MoreItem> items}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _MoreTile(item: item);
      },
    );
  }
}

class _MoreItem {
  final String label;
  final IconData icon;
  final String route;
  const _MoreItem({required this.label, required this.icon, required this.route});
}

const _featureItems = [
  _MoreItem(label: AppStrings.photosLabel, icon: Icons.photo_library_outlined, route: '/more/photos'),
  _MoreItem(label: AppStrings.restaurantsLabel, icon: Icons.restaurant_outlined, route: '/more/restaurants'),
  _MoreItem(label: AppStrings.moviesLabel, icon: Icons.movie_outlined, route: '/more/movies'),
  _MoreItem(label: AppStrings.thoughtsLabel, icon: Icons.lightbulb_outline, route: '/more/thoughts'),
  _MoreItem(label: AppStrings.booksLabel, icon: Icons.menu_book_outlined, route: '/more/books'),
  _MoreItem(label: AppStrings.visionBoardLabel, icon: Icons.dashboard_customize_outlined, route: '/more/vision-board'),
  _MoreItem(label: AppStrings.lifeLessonsLabel, icon: Icons.school_outlined, route: '/more/life-lessons'),
  _MoreItem(label: AppStrings.learningsLabel, icon: Icons.auto_stories_outlined, route: '/more/learnings'),
  _MoreItem(label: AppStrings.firstTimeLabel, icon: Icons.star_outline, route: '/more/first-time'),
  _MoreItem(label: AppStrings.moodBoardLabel, icon: Icons.mood_outlined, route: '/more/mood-board'),
  _MoreItem(label: AppStrings.placesVisitedLabel, icon: Icons.place_outlined, route: '/more/places-visited'),
  _MoreItem(label: AppStrings.miscellaneousLabel, icon: Icons.widgets_outlined, route: '/more/miscellaneous'),
];

class _MoreTile extends StatelessWidget {
  final _MoreItem item;
  const _MoreTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: AppSpacing.borderRadiusMd,
      onTap: () => context.push(item.route),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 28, color: theme.colorScheme.primary),
            AppSpacing.gapXs,
            Text(
              item.label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
