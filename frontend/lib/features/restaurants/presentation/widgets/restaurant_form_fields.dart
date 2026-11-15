import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';

/// Form pieces shared by the Add Restaurant and Log Visit sheets.

/// Picked photos as one draft value. Paths are joined into a single String
/// (not a List) so the draft mixin's shallow equality check can tell
/// "unchanged" from "changed".
String encodePhotoPaths(List<File> photos) => photos.map((f) => f.path).join('\n');

/// Inverse of [encodePhotoPaths]; skips files that no longer exist (e.g. the
/// picker's temp copy was cleaned up).
List<File> decodePhotoPaths(String? encoded) => (encoded == null || encoded.isEmpty)
    ? <File>[]
    : encoded.split('\n').map(File.new).where((f) => f.existsSync()).toList();

/// "Rating ............ ★ 3.5" with a 1–5 slider in half steps.
class RatingField extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const RatingField({super.key, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _FieldPanel(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md - 4, AppSpacing.md, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              const Icon(Icons.star_rounded, size: AppSpacing.md + 4, color: AppColors.chartLemon),
              AppSpacing.hGapXs,
              Text(value.toStringAsFixed(1), style: theme.textTheme.titleMedium),
            ],
          ),
          Slider(value: value, min: 1, max: 5, divisions: 8, label: value.toStringAsFixed(1), onChanged: onChanged),
        ],
      ),
    );
  }
}

/// "♥ Mark as favourite ........ [switch]"
class FavouriteToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const FavouriteToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _FieldPanel(
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        secondary: Icon(
          value ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: value ? AppColors.error : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(AppStrings.markAsFavourite, style: theme.textTheme.bodyLarge),
      ),
    );
  }
}

/// "Photos (2)" heading plus a strip: [+ add] [thumb ×] [thumb ×] …
class PhotoPickerStrip extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const PhotoPickerStrip({super.key, required this.photos, required this.onAdd, required this.onRemove});

  static const double _tile = AppSpacing.visitPhotoSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          photos.isEmpty ? AppStrings.photosCount : '${AppStrings.photosCount} (${photos.length})',
          style: theme.textTheme.titleSmall,
        ),
        AppSpacing.gapSm,
        SizedBox(
          height: _tile,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length + 1,
            separatorBuilder: (_, _) => AppSpacing.hGapSm,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Tooltip(
                  message: AppStrings.addPhotos,
                  child: Material(
                    color: colors.surfaceContainerHigh,
                    borderRadius: AppSpacing.borderRadiusLg,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onAdd,
                      child: SizedBox.square(
                        dimension: _tile,
                        child: Icon(Icons.add_photo_alternate_outlined, color: colors.primary),
                      ),
                    ),
                  ),
                );
              }
              final i = index - 1;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppSpacing.borderRadiusLg,
                    child: Image.file(photos[i], width: _tile, height: _tile, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: Material(
                      color: colors.surface,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onRemove(i),
                        child: Tooltip(
                          message: AppStrings.removePhoto,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.close_rounded, size: AppSpacing.md, color: colors.onSurface),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Rounded tinted panel matching the filled input fields.
class _FieldPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _FieldPanel({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: AppSpacing.borderRadiusLg,
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
