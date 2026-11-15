import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const StorageImage({
    super.key,
    required this.bucket,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(signedUrlProvider((bucket: bucket, path: path)));

    return url.when(
      loading: () => _Placeholder(width: width, height: height),
      error: (_, _) => _Placeholder(width: width, height: height, broken: true),
      data: (url) => Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _Placeholder(width: width, height: height),
        errorBuilder: (context, _, _) => _Placeholder(width: width, height: height, broken: true),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double? width;
  final double? height;
  final bool broken;

  const _Placeholder({this.width, this.height, this.broken = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: colors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: broken ? Icon(Icons.broken_image_outlined, color: colors.onSurfaceVariant) : null,
    );
  }
}
