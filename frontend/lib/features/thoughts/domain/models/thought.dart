import 'package:equatable/equatable.dart';
import 'package:chronicle/core/utils/tags.dart';

class Thought extends Equatable {
  final String id;
  final String userId;
  final String content;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Thought({
    required this.id,
    required this.userId,
    required this.content,
    this.tags = const [],
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Thought.fromJson(Map<String, dynamic> json) {
    return Thought(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      // `text[]` after the 20261117 migration; legacy rows are comma text.
      tags: TagUtils.fromJson(json['tags']),
      isFavorite: json['is_favorite'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, userId, content, tags, isFavorite, createdAt, updatedAt];
}
