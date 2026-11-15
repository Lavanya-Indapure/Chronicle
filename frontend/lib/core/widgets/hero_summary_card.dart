import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';

/// One figure in the bottom row of a [HeroSummaryCard].
class HeroStat {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const HeroStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });
}

/// The lemon "Total Balance"-style card: title, large amount, optional badge
/// pill, and up to two supporting stats underneath.
class HeroSummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final String? badge;
  final IconData? badgeIcon;
  final List<HeroStat> stats;

  /// Left-aligned, shorter layout: title and badge share the top row and the
  /// amount is one size smaller.
  final bool compact;

  const HeroSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    this.badge,
    this.badgeIcon,
    this.stats = const [],
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = colors.onPrimaryContainer;

    if (compact) return _buildCompact(theme, colors, ink);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.cardPadding,
        AppSpacing.lg,
        AppSpacing.cardPadding,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: AppSpacing.borderRadiusXxl),
      child: Column(
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(color: ink)),
          AppSpacing.gapXs,
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(amount, style: theme.textTheme.displayMedium?.copyWith(color: ink)),
          ),
          if (badge != null) ...[
            AppSpacing.gapSm,
            _Badge(text: badge!, icon: badgeIcon),
          ],
          if (stats.isNotEmpty) ...[
            AppSpacing.gapLg,
            Row(
              children: [
                for (final stat in stats) Expanded(child: _StatTile(stat: stat, ink: ink)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompact(ThemeData theme, ColorScheme colors, Color ink) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: AppSpacing.borderRadiusXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleSmall?.copyWith(color: ink))),
              if (badge != null) _Badge(text: badge!, icon: badgeIcon),
            ],
          ),
          AppSpacing.gapXs,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(amount, style: theme.textTheme.headlineLarge?.copyWith(color: ink, fontWeight: FontWeight.w700)),
          ),
          if (stats.isNotEmpty) ...[
            AppSpacing.gapMd,
            Divider(height: 1, color: ink.withValues(alpha: 0.12)),
            AppSpacing.gapMd,
            Row(
              children: [
                for (final stat in stats) Expanded(child: _StatTile(stat: stat, ink: ink, compact: true)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _Badge({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md - 4, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: colors.onPrimaryContainer, borderRadius: AppSpacing.borderRadiusPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.md, color: colors.primaryContainer),
            AppSpacing.hGapXs,
          ],
          Text(text, style: theme.textTheme.labelMedium?.copyWith(color: colors.primaryContainer)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final HeroStat stat;
  final Color ink;
  final bool compact;

  const _StatTile({required this.stat, required this.ink, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = compact ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall;
    return Row(
      children: [
        IconBadge(
          icon: stat.icon,
          color: stat.iconColor,
          onColor: ink,
          filled: true,
          size: compact ? AppSpacing.xl : AppSpacing.xl + 6,
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  stat.value,
                  style: valueStyle?.copyWith(color: ink, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                stat.label,
                style: theme.textTheme.bodySmall?.copyWith(color: ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
