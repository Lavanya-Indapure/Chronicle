import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_constants.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/empty_state.dart';
import 'package:chronicle/core/widgets/storage_image.dart';
import 'package:chronicle/features/photos/domain/models/photo.dart';
import 'package:chronicle/features/photos/presentation/controllers/photo_controller.dart';
import 'package:chronicle/features/photos/presentation/widgets/add_photo_sheet.dart';

/// Photo grid grouped by month. Tap a photo to view it full screen (with
/// caption, date and delete); long-press to delete from the grid.
class PhotosScreen extends ConsumerWidget {
  const PhotosScreen({super.key});

  static const int _columns = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoControllerProvider);
    final controller = ref.read(photoControllerProvider.notifier);
    final theme = Theme.of(context);
    final hasAny = state.photos.isNotEmpty;

    ref.listen(photoControllerProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next != prev) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.photosLabel)),
      body: state.isLoading && !hasAny
          ? const Center(child: CircularProgressIndicator())
          : !hasAny
              ? EmptyState(
                  icon: Icons.photo_library_outlined,
                  title: AppStrings.noPhotosTitle,
                  message: AppStrings.noPhotosMessage,
                  actionLabel: AppStrings.addFirstPhoto,
                  onAction: () => _showAddPhoto(context),
                )
              : RefreshIndicator(
                  onRefresh: controller.loadPhotos,
                  child: CustomScrollView(
                    slivers: [
                      for (final MapEntry(key: month, value: photos) in state.photosByMonth.entries) ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.sm),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    AppFormatters.monthYear(month),
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  '${photos.length} ${photos.length == 1 ? AppStrings.photoSingular : AppStrings.photoPlural}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: AppSpacing.paddingGutter,
                          sliver: SliverGrid.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _columns,
                              crossAxisSpacing: AppSpacing.sm,
                              mainAxisSpacing: AppSpacing.sm,
                            ),
                            itemCount: photos.length,
                            itemBuilder: (context, index) => _PhotoTile(
                              photo: photos[index],
                              onOpen: () => _openViewer(context, photos[index]),
                              onDelete: () => _confirmAndDelete(context, ref, photos[index]),
                            ),
                          ),
                        ),
                      ],
                      // Keeps the last row clear of the FAB.
                      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl + AppSpacing.xl)),
                    ],
                  ),
                ),
      floatingActionButton: hasAny
          ? FloatingActionButton.extended(
              onPressed: () => _showAddPhoto(context),
              label: const Text(AppStrings.addPhoto),
              icon: const Icon(Icons.add_a_photo_outlined),
            )
          : null,
    );
  }

  void _showAddPhoto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const AddPhotoSheet(),
    );
  }

  void _openViewer(BuildContext context, Photo photo) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PhotoViewer(photo: photo)));
  }
}

/// Confirms, then deletes. Returns true if the photo was deleted.
Future<bool> _confirmAndDelete(BuildContext context, WidgetRef ref, Photo photo) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(AppStrings.deletePhotoTitle),
      content: const Text(AppStrings.deletePhotoMessage),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text(AppStrings.delete),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  return ref.read(photoControllerProvider.notifier).deletePhoto(photo);
}

class _PhotoTile extends StatelessWidget {
  final Photo photo;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _PhotoTile({required this.photo, required this.onOpen, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: photo.caption ?? AppFormatters.dayMonthYear(photo.photoDate),
      child: GestureDetector(
        onTap: onOpen,
        onLongPress: onDelete,
        child: Hero(
          tag: photo.id,
          child: ClipRRect(
            borderRadius: AppSpacing.borderRadiusLg,
            child: StorageImage(bucket: AppConstants.photosBucket, path: photo.storagePath),
          ),
        ),
      ),
    );
  }
}

/// Full-screen viewer on a dark backdrop with pinch-zoom, caption, date and
/// a delete action.
class _PhotoViewer extends ConsumerWidget {
  final Photo photo;

  const _PhotoViewer({required this.photo});

  // The viewer stays dark in both themes, like most photo viewers.
  static const _backdrop = AppColors.ink;
  static const _onBackdrop = AppColors.darkTextPrimary;
  static const _onBackdropMuted = AppColors.darkTextSecondary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final caption = photo.caption?.trim();

    return Scaffold(
      backgroundColor: _backdrop,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: _onBackdrop,
        actions: [
          IconButton(
            tooltip: AppStrings.delete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final deleted = await _confirmAndDelete(context, ref, photo);
              if (deleted && context.mounted) Navigator.pop(context);
            },
          ),
          AppSpacing.hGapXs,
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              child: Hero(
                tag: photo.id,
                child: StorageImage(bucket: AppConstants.photosBucket, path: photo.storagePath, fit: BoxFit.contain, fullScreen: true),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [_backdrop.withValues(alpha: 0.9), _backdrop.withValues(alpha: 0)],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (caption != null && caption.isNotEmpty) ...[
                        Text(caption, style: theme.textTheme.titleMedium?.copyWith(color: _onBackdrop)),
                        AppSpacing.gapXs,
                      ],
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: AppSpacing.md, color: _onBackdropMuted),
                          AppSpacing.hGapSm,
                          Text(
                            AppFormatters.dayMonthYear(photo.photoDate),
                            style: theme.textTheme.bodySmall?.copyWith(color: _onBackdropMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
