import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/presentation/widgets/category_visuals.dart';

/// "(🛍) Shop / Shop ........ -₹120 / Essential" row.
class ExpenseListTile extends StatelessWidget {
  final Expense expense;
  final Color color;

  const ExpenseListTile({super.key, required this.expense, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryName = expense.category?.name;
    final title = expense.description ?? categoryName ?? AppStrings.expenseFallbackTitle;

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md - 4),
      child: Row(
        children: [
          IconBadge(icon: CategoryVisuals.iconFor(categoryName), color: color),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  categoryName ?? AppStrings.uncategorized,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${AppFormatters.currency(expense.amount)}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                expense.isNecessary ? AppStrings.essential : AppStrings.nonEssential,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: expense.isNecessary ? null : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
