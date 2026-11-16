import 'package:equatable/equatable.dart';

/// A free-form entry: optional title, plus a note and/or one picture
/// (stored in the `misc` bucket at [storagePath]).
class MiscItem extends Equatable {
  final String id;
  final String userId;
  final String? title;
  final String? content;
  final String? storagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MiscItem({
    required this.id,
    required this.userId,
    this.title,
    this.content,
    this.storagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasImage => storagePath != null && storagePath!.isNotEmpty;

  factory MiscItem.fromJson(Map<String, dynamic> json) {
    return MiscItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String?,
      storagePath: json['storage_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, userId, title, content, storagePath, createdAt, updatedAt];
}
