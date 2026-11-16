import 'dart:io';
import 'package:chronicle/features/miscellaneous/domain/models/misc_item.dart';

abstract class MiscRepository {
  Future<List<MiscItem>> getItems();
  Future<void> createItem({String? title, String? content, File? image});

  /// Updates text fields. A [newImage] replaces the current picture;
  /// [removeImage] drops it. The old file is removed from storage.
  Future<void> updateItem(
    MiscItem item, {
    String? title,
    String? content,
    File? newImage,
    bool removeImage = false,
  });

  /// Soft delete: the row is kept with `deleted_at` set (its picture stays
  /// in storage).
  Future<void> deleteItem(String id);
}
