import 'package:equatable/equatable.dart';
import 'package:chronicle/core/utils/tags.dart';

class Book extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? author;
  final String? takeaways;
  final String status;
  final double? rating;
  final bool isFavorite;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Book({
    required this.id,
    required this.userId,
    required this.name,
    this.author,
    this.takeaways,
    required this.status,
    this.rating,
    required this.isFavorite,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      author: json['author'],
      takeaways: json['takeaways'],
      status: json['status'] ?? 'reading',
      rating: (json['rating'] as num?)?.toDouble(),
      isFavorite: json['is_favorite'] ?? false,
      tags: TagUtils.fromJson(json['tags']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, userId, name, author, takeaways, status, rating, isFavorite, tags, createdAt, updatedAt];
}
