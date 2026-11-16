import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_constants.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/storage_image.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/miscellaneous/domain/models/misc_item.dart';

/// One item: picture (if any) across the top, then title, note and date.
/// Tap to edit.
class MiscItemCard extends StatelessWidget {
  /// Height of the picture banner.
  static const double imageHeight = 180;

  final MiscItem item;
  final VoidCallback onTap;

  const MiscItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = item.title?.trim();
    final content = item.content?.trim();

    return SurfaceCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.hasImage)
            SizedBox(
              height: imageHeight,
              child: StorageImage(bucket: AppConstants.miscBucket, path: item.storagePath!),
            ),
          Padding(
            padding: AppSpacing.paddingCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && title.isNotEmpty) ...[
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  AppSpacing.gapXs,
                ],
                if (content != null && content.isNotEmpty) ...[
                  Text(content, style: theme.textTheme.bodyMedium, maxLines: 6, overflow: TextOverflow.ellipsis),
                  AppSpacing.gapSm,
                ],
                Text(AppFormatters.dayMonthYear(item.createdAt), style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
