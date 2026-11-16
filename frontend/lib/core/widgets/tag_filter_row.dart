import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';

/// Horizontal "All · #career · #patience" single-select filter chips used
/// by every taggable list screen.
class TagFilterRow extends StatelessWidget {
  final List<String> tags;
  final String? selected;
  final ValueChanged<String?> onSelected;

  /// Horizontal padding of the scrolling row; zero when the row already
  /// sits inside padded content.
  final EdgeInsetsGeometry padding;

  const TagFilterRow({
    super.key,
    required this.tags,
    required this.selected,
    required this.onSelected,
    this.padding = AppSpacing.paddingGutter,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.xxl - AppSpacing.xs,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: tags.length + 1,
        separatorBuilder: (_, _) => AppSpacing.hGapSm,
        itemBuilder: (context, index) {
          if (index == 0) {
            return ChoiceChip(
              showCheckmark: false,
              label: const Text(AppStrings.journalAll),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            );
          }
          final tag = tags[index - 1];
          return ChoiceChip(
            showCheckmark: false,
            label: Text('#$tag'),
            selected: selected == tag,
            onSelected: (v) => onSelected(v ? tag : null),
          );
        },
      ),
    );
  }
}
