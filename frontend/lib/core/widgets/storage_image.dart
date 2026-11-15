import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/providers/signed_url_provider.dart';

/// Image stored in Supabase Storage, loaded through a signed URL so it works
/// with private buckets. Shows a neutral placeholder while loading and a
/// small broken-image tile (not a red error box) if it can't be loaded.
class StorageImage extends ConsumerWidget {
  final String bucket;
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Full-screen style: transparent placeholder with a spinner while loading
  /// (for viewers on a dark backdrop) instead of a filled tile.
  final bool fullScreen;

  const StorageImage({
    super.key,
    required this.bucket,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(signedUrlProvider((bucket: bucket, path: path)));
    Widget placeholder({bool broken = false}) =>
        _Placeholder(width: width, height: height, broken: broken, fullScreen: fullScreen);

    return url.when(
      loading: placeholder,
      error: (_, _) => placeholder(broken: true),
      data: (url) => Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, progress) => progress == null ? child : placeholder(),
        errorBuilder: (context, _, _) => placeholder(broken: true),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double? width;
  final double? height;
  final bool broken;
  final bool fullScreen;

  const _Placeholder({this.width, this.height, this.broken = false, this.fullScreen = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: fullScreen ? null : colors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: broken
          ? Icon(Icons.broken_image_outlined, color: colors.onSurfaceVariant, size: fullScreen ? AppSpacing.xxl : null)
          : (fullScreen ? const CircularProgressIndicator() : null),
    );
  }
}
