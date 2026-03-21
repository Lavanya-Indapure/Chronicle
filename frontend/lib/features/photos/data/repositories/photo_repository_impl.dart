import 'dart:io';
import 'package:chronicle/features/photos/domain/models/photo.dart';
import 'package:chronicle/features/photos/domain/repositories/photo_repository.dart';
import 'package:chronicle/features/photos/data/datasources/photo_remote_datasource.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  final PhotoRemoteDatasource _datasource;

  PhotoRepositoryImpl(this._datasource);

  @override
  Future<List<Photo>> getPhotos() async {
    return await _datasource.getPhotos();
  }

  @override
  Future<Photo> uploadPhoto({
    required File file,
    String? caption,
    required DateTime date,
  }) async {
    return await _datasource.uploadPhoto(
      file: file,
      caption: caption,
      date: date,
    );
  }

  @override
  Future<void> deletePhoto(Photo photo) async {
    await _datasource.deletePhoto(photo);
  }
}
