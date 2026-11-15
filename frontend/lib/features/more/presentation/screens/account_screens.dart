import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/theme/theme_controller.dart';
import 'package:chronicle/core/utils/dialog_utils.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/pill_tabs.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/more/presentation/controllers/user_profile_provider.dart';
import 'package:chronicle/features/more/presentation/widgets/profile_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const double _avatarSize = AppSpacing.xxxl + AppSpacing.lg; // 88

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xl),
        children: [
          Center(child: ProfileAvatar(initial: profile?.initial ?? '?', size: _avatarSize)),
          AppSpacing.gapMd,
          Text(
            profile?.fullName ?? AppStrings.unknownUser,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (profile?.email != null)
            Text(profile!.email!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          AppSpacing.gapXl,
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.mail_outline_rounded,
                  color: AppColors.chartBlue,
                  label: AppStrings.profileEmail,
                  value: profile?.email ?? AppStrings.noEmail,
                ),
                Divider(height: 1, color: theme.colorScheme.outline, indent: AppSpacing.md + AppSpacing.iconBadgeSize + AppSpacing.md),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.chartGreen,
                  label: AppStrings.memberSince,
                  value: profile?.memberSince == null ? '—' : AppFormatters.dayMonthYear(profile!.memberSince!),
                ),
              ],
            ),
          ),
          AppSpacing.gapLg,
          OutlinedButton.icon(
            onPressed: () => DialogUtils.showLogoutDialog(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(AppStrings.logOut),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(value, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => AppStrings.themeSystem,
        ThemeMode.light => AppStrings.themeLight,
        ThemeMode.dark => AppStrings.themeDark,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xl),
        children: [
          const SectionHeader(title: AppStrings.appearance, compact: true),
          AppSpacing.gapSm,
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const IconBadge(icon: Icons.dark_mode_rounded, color: AppColors.chartOrchid),
                    AppSpacing.hGapMd,
                    Text(AppStrings.themeLabel, style: theme.textTheme.titleMedium),
                  ],
                ),
                AppSpacing.gapMd,
                PillTabs<ThemeMode>(
                  values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
                  labelOf: _themeLabel,
                  selected: themeMode,
                  onChanged: ref.read(themeControllerProvider.notifier).setThemeMode,
                ),
                AppSpacing.gapSm,
                Text(AppStrings.themeHint, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          AppSpacing.gapLg,
          const SectionHeader(title: AppStrings.about, compact: true),
          AppSpacing.gapSm,
          SurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const IconBadge(icon: Icons.info_outline_rounded, color: AppColors.chartBlue),
                AppSpacing.hGapMd,
                Expanded(child: Text(AppStrings.version, style: theme.textTheme.titleMedium)),
                Text(AppStrings.appVersion, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
