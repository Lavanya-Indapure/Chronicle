import 'package:equatable/equatable.dart';

class Photo extends Equatable {
  final String id;
  final String userId;
  final String storagePath;
  final String imageUrl;
  final String? caption;
  final DateTime photoDate;
  final DateTime createdAt;

  const Photo({
    required this.id,
    required this.userId,
    required this.storagePath,
    required this.imageUrl,
    this.caption,
    required this.photoDate,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      userId: json['user_id'],
      storagePath: json['storage_path'],
      imageUrl: json['image_url'],
      caption: json['caption'],
      photoDate: DateTime.parse(json['photo_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'storage_path': storagePath,
      'image_url': imageUrl,
      'caption': caption,
      'photo_date': photoDate.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, storagePath, imageUrl, caption, photoDate, createdAt];
}
