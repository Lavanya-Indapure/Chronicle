import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/features/learnings/presentation/widgets/journal_widgets.dart';
import 'package:chronicle/features/search/domain/search_models.dart';
import 'package:chronicle/features/search/presentation/widgets/highlighted_text.dart';
import 'package:chronicle/features/search/presentation/widgets/search_module_style.dart';

/// One search hit: module icon, title/subtitle with the match highlighted,
/// tags, and date (plus amount for expenses).
class SearchResultTile extends StatelessWidget {
  /// Tags shown before collapsing to "+N".
  static const _maxTags = 3;

  final SearchResult result;
  final String query;
  final VoidCallback onTap;

  const SearchResultTile({super.key, required this.result, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final module = result.module;
    final extraTags = result.tags.length - _maxTags;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusLg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm + AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: module.icon, color: module.color, size: AppSpacing.xl + AppSpacing.xs),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HighlightedText(
                    text: result.title,
                    query: query,
                    maxLines: 2,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (result.subtitle != null)
                    HighlightedText(text: result.subtitle!, query: query, style: theme.textTheme.bodySmall),
                  if (result.tags.isNotEmpty) ...[
                    AppSpacing.gapXs,
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final tag in result.tags.take(_maxTags)) TagPill(text: '#$tag', color: module.color),
                        if (extraTags > 0) TagPill(text: '+$extraTags', color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.hGapSm,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (result.amount != null)
                  Text(AppFormatters.currency(result.amount!), style: theme.textTheme.titleSmall),
                if (result.date != null) Text(AppFormatters.dayMonthYear(result.date!), style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
