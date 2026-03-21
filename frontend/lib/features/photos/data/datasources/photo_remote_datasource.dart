import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/photos/domain/models/photo.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class PhotoRemoteDatasource {
  final SupabaseClient _client;

  PhotoRemoteDatasource(this._client);

  Future<List<Photo>> getPhotos() async {
    try {
      final response = await _client
          .from('photos')
          .select()
          .order('photo_date', ascending: false);
      
      return (response as List).map((json) => Photo.fromJson(json)).toList();
    } catch (e) {
      throw AppException('Failed to fetch photos: $e');
    }
  }

  Future<Photo> uploadPhoto({
    required File file,
    String? caption,
    required DateTime date,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storagePath = '$userId/$fileName';

      // 1. Upload to Storage
      await _client.storage.from('photos').upload(storagePath, file);

      // 2. Get Public URL
      final imageUrl = _client.storage.from('photos').getPublicUrl(storagePath);

      // 3. Insert into Database
      final response = await _client.from('photos').insert({
        'user_id': userId,
        'storage_path': storagePath,
        'image_url': imageUrl,
        'caption': caption,
        'photo_date': date.toIso8601String(),
      }).select().single();

      return Photo.fromJson(response);
    } catch (e) {
      throw AppException('Failed to upload photo: $e');
    }
  }

  Future<void> deletePhoto(Photo photo) async {
    try {
      // 1. Delete from Storage
      await _client.storage.from('photos').remove([photo.storagePath]);

      // 2. Delete from Database
      await _client.from('photos').delete().eq('id', photo.id);
    } catch (e) {
      throw AppException('Failed to delete photo: $e');
    }
  }
}
