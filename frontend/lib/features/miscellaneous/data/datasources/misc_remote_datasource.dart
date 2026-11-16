import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/core/constants/app_constants.dart';
import 'package:chronicle/core/errors/app_exception.dart';
import 'package:chronicle/features/miscellaneous/domain/models/misc_item.dart';

/// Supabase calls for the `misc_items` table and the private `misc` bucket.
/// Pictures live at `<user_id>/<timestamp>_<file name>`, like Photos.
class MiscRemoteDatasource {
  static const _table = 'misc_items';

  final SupabaseClient _client;

  MiscRemoteDatasource(this._client);

  StorageFileApi get _bucket => _client.storage.from(AppConstants.miscBucket);

  Future<List<MiscItem>> getItems() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);
      return (response as List).map((json) => MiscItem.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw AppException('Failed to fetch items: $e', originalError: e);
    }
  }

  Future<void> createItem({String? title, String? content, File? image}) async {
    String? uploaded;
    try {
      if (image != null) uploaded = await _upload(image);
      await _client.from(_table).insert({
        'user_id': _client.auth.currentUser!.id,
        'title': title,
        'content': content,
        'storage_path': uploaded,
      });
    } catch (e) {
      if (uploaded != null) await _removeQuietly(uploaded);
      throw AppException('Failed to save item: $e', originalError: e);
    }
  }

  Future<void> updateItem(
    MiscItem item, {
    String? title,
    String? content,
    File? newImage,
    bool removeImage = false,
  }) async {
    String? uploaded;
    try {
      if (newImage != null) uploaded = await _upload(newImage);
      final path = uploaded ?? (removeImage ? null : item.storagePath);
      await _client.from(_table).update({
        'title': title,
        'content': content,
        'storage_path': path,
      }).eq('id', item.id);

      // The previous picture is no longer referenced by anything.
      if (item.hasImage && path != item.storagePath) await _removeQuietly(item.storagePath!);
    } catch (e) {
      if (uploaded != null) await _removeQuietly(uploaded);
      throw AppException('Failed to update item: $e', originalError: e);
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _client
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
    } catch (e) {
      throw AppException('Failed to delete item: $e', originalError: e);
    }
  }

  Future<String> _upload(File file) async {
    final userId = _client.auth.currentUser!.id;
    final name = file.path.split(RegExp(r'[\\/]')).last;
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$name';
    await _bucket.upload(path, file);
    return path;
  }

  /// Best-effort cleanup; a leftover file is harmless.
  Future<void> _removeQuietly(String path) async {
    try {
      await _bucket.remove([path]);
    } catch (_) {}
  }
}
