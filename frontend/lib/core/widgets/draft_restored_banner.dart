import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';

/// "✎ Draft restored ........ Discard" strip shown at the top of a form
/// sheet that reopened with unsaved input (see DraftFormMixin).
class DraftRestoredBanner extends StatelessWidget {
  final VoidCallback onDiscard;

  const DraftRestoredBanner({super.key, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs),
      decoration: BoxDecoration(color: colors.surfaceContainerHigh, borderRadius: AppSpacing.borderRadiusPill),
      child: Row(
        children: [
          Icon(Icons.edit_note_rounded, size: AppSpacing.md + 4, color: colors.primary),
          AppSpacing.hGapSm,
          Expanded(child: Text(AppStrings.draftRestored, style: theme.textTheme.labelMedium)),
          TextButton(onPressed: onDiscard, child: const Text(AppStrings.discardDraft)),
        ],
      ),
    );
  }
}
