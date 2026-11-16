import 'dart:io';
import 'package:chronicle/features/miscellaneous/data/datasources/misc_remote_datasource.dart';
import 'package:chronicle/features/miscellaneous/domain/models/misc_item.dart';
import 'package:chronicle/features/miscellaneous/domain/repositories/misc_repository.dart';

class MiscRepositoryImpl implements MiscRepository {
  final MiscRemoteDatasource _datasource;

  MiscRepositoryImpl(this._datasource);

  @override
  Future<List<MiscItem>> getItems() => _datasource.getItems();

  @override
  Future<void> createItem({String? title, String? content, File? image}) =>
      _datasource.createItem(title: title, content: content, image: image);

  @override
  Future<void> updateItem(
    MiscItem item, {
    String? title,
    String? content,
    File? newImage,
    bool removeImage = false,
  }) =>
      _datasource.updateItem(item, title: title, content: content, newImage: newImage, removeImage: removeImage);

  @override
  Future<void> deleteItem(String id) => _datasource.deleteItem(id);
}
