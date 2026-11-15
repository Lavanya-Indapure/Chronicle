import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/surface_card.dart';

/// One-line debts overview: "Debts · ₹600 you owe · ₹1,500 owed to you ›".
/// Debts aren't tied to a month, so they live on their own screen.
class DebtsSummaryRow extends StatelessWidget {
  final double youOwe;
  final double owedToYou;
  final int pendingCount;
  final VoidCallback onTap;

  const DebtsSummaryRow({
    super.key,
    required this.youOwe,
    required this.owedToYou,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const IconBadge(icon: Icons.swap_horiz_rounded, color: AppColors.chartBlue),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pendingCount > 0 ? '${AppStrings.debts} · $pendingCount' : AppStrings.debts,
                  style: theme.textTheme.titleMedium,
                ),
                if (pendingCount == 0)
                  Text(AppStrings.noPendingDebts, style: theme.textTheme.bodySmall)
                else
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodySmall,
                      children: [
                        if (youOwe > 0) ...[
                          TextSpan(
                            text: AppFormatters.currency(youOwe),
                            style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ' ${AppStrings.oweLower}'),
                        ],
                        if (youOwe > 0 && owedToYou > 0) const TextSpan(text: '  ·  '),
                        if (owedToYou > 0) ...[
                          TextSpan(
                            text: AppFormatters.currency(owedToYou),
                            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ' ${AppStrings.owedLower}'),
                        ],
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }
}
