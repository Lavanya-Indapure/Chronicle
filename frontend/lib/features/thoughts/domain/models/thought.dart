import 'package:equatable/equatable.dart';

class Thought extends Equatable {
  final String id;
  final String userId;
  final String content;
  final String? tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Thought({
    required this.id,
    required this.userId,
    required this.content,
    this.tags,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Thought.fromJson(Map<String, dynamic> json) {
    return Thought(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      tags: json['tags'],
      isFavorite: json['is_favorite'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, userId, content, tags, isFavorite, createdAt, updatedAt];
}
