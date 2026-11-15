import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/dialog_utils.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/more/presentation/controllers/user_profile_provider.dart';
import 'package:chronicle/features/more/presentation/widgets/profile_avatar.dart';

/// More tab: profile card, then every other feature grouped by theme,
/// then account actions.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const _sections = [
    _MoreSection(AppStrings.moreSectionMemories, [
      _MoreItem(AppStrings.photosLabel, Icons.photo_library_rounded, AppColors.chartOrchid, '/more/photos'),
      _MoreItem(AppStrings.placesVisitedLabel, Icons.place_rounded, AppColors.chartTeal, '/more/places-visited'),
      _MoreItem(AppStrings.firstTimeLabel, Icons.auto_awesome_rounded, AppColors.chartLemon, '/more/first-time'),
    ]),
    _MoreSection(AppStrings.moreSectionMedia, [
      _MoreItem(AppStrings.booksLabel, Icons.menu_book_rounded, AppColors.chartBlue, '/more/books'),
      _MoreItem(AppStrings.moviesLabel, Icons.movie_rounded, AppColors.chartCoral, '/more/movies'),
      _MoreItem(AppStrings.restaurantsLabel, Icons.restaurant_rounded, AppColors.chartOrange, '/more/restaurants'),
    ]),
    _MoreSection(AppStrings.moreSectionMind, [
      _MoreItem(AppStrings.thoughtsLabel, Icons.lightbulb_rounded, AppColors.chartLemon, '/more/thoughts'),
      _MoreItem(AppStrings.learningsLabel, Icons.school_rounded, AppColors.chartGreen, '/more/learnings'),
      _MoreItem(AppStrings.moodBoardLabel, Icons.mood_rounded, AppColors.chartOrchid, '/more/mood-board'),
      _MoreItem(AppStrings.visionBoardLabel, Icons.flag_rounded, AppColors.chartBlue, '/more/vision-board'),
      _MoreItem(AppStrings.lifeLessonsLabel, Icons.psychology_rounded, AppColors.chartTeal, '/more/life-lessons'),
      _MoreItem(AppStrings.miscellaneousLabel, Icons.widgets_rounded, AppColors.chartGreen, '/more/miscellaneous'),
    ]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.lg),
          children: [
            Text(AppStrings.moreLabel, style: Theme.of(context).textTheme.headlineMedium),
            AppSpacing.gapMd,
            _ProfileCard(profile: profile, onTap: () => context.push('/more/profile')),
            for (final section in _sections) ...[
              AppSpacing.gapLg,
              SectionHeader(title: section.title, compact: true),
              AppSpacing.gapSm,
              _FeatureGrid(items: section.items),
            ],
            AppSpacing.gapLg,
            const SectionHeader(title: AppStrings.account, compact: true),
            AppSpacing.gapSm,
            _AccountCard(
              onSettings: () => context.push('/more/settings'),
              onLogout: () => DialogUtils.showLogoutDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreSection {
  final String title;
  final List<_MoreItem> items;

  const _MoreSection(this.title, this.items);
}

class _MoreItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const _MoreItem(this.label, this.icon, this.color, this.route);
}

class _ProfileCard extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback onTap;

  const _ProfileCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          ProfileAvatar(initial: profile?.initial ?? '?', size: AppSpacing.avatarSize + AppSpacing.sm),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.fullName ?? AppStrings.unknownUser,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  profile?.email ?? AppStrings.viewProfile,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Three-across grid of feature tiles.
class _FeatureGrid extends StatelessWidget {
  final List<_MoreItem> items;

  const _FeatureGrid({required this.items});

  /// Fixed tile height: badge + two lines of label + padding.
  static const double _tileHeight = AppSpacing.xxxl * 2;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisExtent: _tileHeight,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _FeatureTile(item: items[index]),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final _MoreItem item;

  const _FeatureTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      onTap: () => context.push(item.route),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md - 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconBadge(icon: item.icon, color: item.color),
          AppSpacing.gapSm,
          Text(
            item.label,
            style: theme.textTheme.labelMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Settings + Log out rows in one card.
class _AccountCard extends StatelessWidget {
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const _AccountCard({required this.onSettings, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          _AccountRow(
            icon: Icons.settings_rounded,
            color: AppColors.chartBlue,
            label: AppStrings.settings,
            onTap: onSettings,
          ),
          Divider(height: 1, color: colors.outline, indent: AppSpacing.md + AppSpacing.iconBadgeSize + AppSpacing.md),
          _AccountRow(
            icon: Icons.logout_rounded,
            color: AppColors.error,
            label: AppStrings.logOut,
            labelColor: AppColors.error,
            showChevron: false,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Color? labelColor;
  final bool showChevron;
  final VoidCallback onTap;

  const _AccountRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            IconBadge(icon: icon, color: color),
            AppSpacing.hGapMd,
            Expanded(child: Text(label, style: theme.textTheme.titleMedium?.copyWith(color: labelColor))),
            if (showChevron) Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
