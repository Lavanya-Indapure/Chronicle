import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/providers/supabase_provider.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/circle_icon_button.dart';

/// "(A) Hello Alex / November 2026 ............ (⚙)"
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final firstName = ref.watch(currentUserFirstNameProvider);
    final initial = (firstName ?? AppStrings.appName).characters.first.toUpperCase();

    return Row(
      children: [
        Semantics(
          button: true,
          label: AppStrings.profile,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push('/more/profile'),
            child: CircleAvatar(
              radius: AppSpacing.avatarSize / 2,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: Text(initial, style: theme.textTheme.titleLarge?.copyWith(color: colors.onPrimaryContainer)),
            ),
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppStrings.greeting} ${firstName ?? AppStrings.defaultUserName}',
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(AppFormatters.monthYear(DateTime.now()), style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        CircleIconButton(
          icon: Icons.settings_outlined,
          tooltip: AppStrings.settings,
          onPressed: () => context.push('/more/settings'),
        ),
      ],
    );
  }
}
