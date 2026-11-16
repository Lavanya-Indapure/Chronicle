import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/surface_card.dart';

/// Localised clock time, e.g. "7:30 AM" / "07:30".
String clockTime(BuildContext context, DateTime time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(time));

/// Lemon hero card used at the top of each health screen.
class HealthHeroCard extends StatelessWidget {
  final String title;
  final String value;
  final String? valueSuffix;
  final String? message;
  final Widget? trailing;
  final List<Widget> actions;

  const HealthHeroCard({
    super.key,
    required this.title,
    required this.value,
    this.valueSuffix,
    this.message,
    this.trailing,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onPrimaryContainer;

    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: AppSpacing.borderRadiusXxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(color: ink)),
                    AppSpacing.gapXs,
                    Text.rich(
                      TextSpan(
                        text: value,
                        style: theme.textTheme.displayMedium?.copyWith(color: ink),
                        children: [
                          if (valueSuffix != null)
                            TextSpan(text: ' $valueSuffix', style: theme.textTheme.titleMedium?.copyWith(color: ink)),
                        ],
                      ),
                    ),
                    if (message != null) ...[
                      AppSpacing.gapXs,
                      Text(message!, style: theme.textTheme.bodyMedium?.copyWith(color: ink)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[AppSpacing.hGapMd, trailing!],
            ],
          ),
          if (actions.isNotEmpty) ...[
            AppSpacing.gapMd,
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) AppSpacing.hGapSm,
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Filled ink button for use on [HealthHeroCard].
class HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;

  const HeroActionButton({super.key, required this.icon, required this.label, this.onPressed, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ink = colors.onPrimaryContainer;
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(foregroundColor: ink, side: BorderSide(color: ink.withValues(alpha: 0.4))),
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(backgroundColor: ink, foregroundColor: colors.primaryContainer),
    );
  }
}

/// Tappable summary row on the health home screen.
class HealthFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String? caption;
  final VoidCallback onTap;

  const HealthFeatureCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.caption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: icon, color: color),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium),
                Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (caption != null) Text(caption!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Shows controller errors as a snackbar.
void showHealthError(BuildContext context, String? previous, String? next) {
  if (next != null && next != previous) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
  }
}
