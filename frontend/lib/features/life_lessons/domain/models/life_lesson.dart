import 'package:equatable/equatable.dart';
import 'package:chronicle/core/utils/tags.dart';

/// A lesson learned from life: free text, an optional title and tags.
class LifeLesson extends Equatable {
  final String id;
  final String userId;
  final String? title;
  final String content;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LifeLesson({
    required this.id,
    required this.userId,
    this.title,
    required this.content,
    this.tags = const [],
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LifeLesson.fromJson(Map<String, dynamic> json) {
    return LifeLesson(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String,
      tags: TagUtils.fromJson(json['tags']),
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  LifeLesson copyWith({bool? isFavorite}) => LifeLesson(
        id: id,
        userId: userId,
        title: title,
        content: content,
        tags: tags,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Splits "growth, Patience ,growth" into ["growth", "Patience"]:
  /// trimmed, blanks dropped, duplicates (case-insensitive) removed.
  static List<String> parseTags(String input) => TagUtils.parse(input);

  @override
  List<Object?> get props => [id, userId, title, content, tags, isFavorite, createdAt, updatedAt];
}
