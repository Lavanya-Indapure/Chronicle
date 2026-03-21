import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/photos/presentation/controllers/photo_controller.dart';
import 'package:chronicle/features/photos/presentation/widgets/add_photo_sheet.dart';
import 'package:chronicle/features/photos/domain/models/photo.dart';

class PhotosScreen extends ConsumerWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(photoControllerProvider.notifier).loadPhotos(),
          ),
        ],
      ),
      body: state.isLoading && state.photos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.photos.isEmpty
              ? _EmptyGallery()
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: state.photos.length,
                  itemBuilder: (context, index) {
                    final photo = state.photos[index];
                    return _PhotoThumbnail(photo: photo);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPhoto(context),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  void _showAddPhoto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => const AddPhotoSheet(),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final Photo photo;

  const _PhotoThumbnail({required this.photo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPhotoView(context),
      onLongPress: () => _showDeleteConfirmation(context),
      child: Hero(
        tag: photo.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Image.network(
            photo.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoView(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _PhotoDetailView(photo: photo),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('This will permanently remove the photo and its caption.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          Consumer(
            builder: (context, ref, child) => TextButton(
              onPressed: () {
                ref.read(photoControllerProvider.notifier).deletePhoto(photo);
                Navigator.pop(ctx);
              },
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoDetailView extends StatelessWidget {
  final Photo photo;

  const _PhotoDetailView({required this.photo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Hero(
                tag: photo.id,
                child: Image.network(photo.imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
          if (photo.caption != null && photo.caption!.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      photo.caption!,
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    AppSpacing.gapXs,
                    Text(
                      photo.photoDate.toString().split(' ').first,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: theme.disabledColor),
          AppSpacing.gapMd,
          Text('No photos yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor)),
          AppSpacing.gapSm,
          Text('Capture your memories!', style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor)),
        ],
      ),
    );
  }
}
