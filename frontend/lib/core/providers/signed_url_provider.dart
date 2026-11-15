import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_constants.dart';
import 'package:chronicle/core/providers/supabase_provider.dart';

/// A file in Supabase Storage.
typedef StorageObject = ({String bucket, String path});

/// Signed, time-limited URL for a file in a (private) storage bucket.
///
/// Public URLs only work for public buckets; signed URLs work for private
/// ones too, as long as the signed-in user may read the file. Cached per
/// file and refreshed shortly before it expires.
///
/// Failures (missing file, no read permission) aren't retried — Riverpod's
/// default retry would leave the image stuck on its loading placeholder.
final signedUrlProvider = FutureProvider.family<String, StorageObject>(
  (ref, object) async {
    final client = ref.watch(supabaseClientProvider);
    final ttl = AppConstants.signedUrlTtl;
    final url = await client.storage.from(object.bucket).createSignedUrl(object.path, ttl.inSeconds);

    final refresh = Timer(ttl - const Duration(minutes: 5), ref.invalidateSelf);
    ref.onDispose(refresh.cancel);
    return url;
  },
  retry: (retryCount, error) => null,
);
