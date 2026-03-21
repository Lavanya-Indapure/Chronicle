import 'dart:io';
import 'package:chronicle/features/photos/domain/models/photo.dart';

abstract class PhotoRepository {
  Future<List<Photo>> getPhotos();
  Future<Photo> uploadPhoto({
    required File file,
    String? caption,
    required DateTime date,
  });
  Future<void> deletePhoto(Photo photo);
}
