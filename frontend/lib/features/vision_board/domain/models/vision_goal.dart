import 'package:equatable/equatable.dart';

enum VisionCategory {
  personal,
  career,
  health,
  finance,
  hobby,
  other,
}

enum VisionStatus {
  notStarted,
  inProgress,
  completed,
}

class VisionGoal extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? category;
  final String duration; // 1m, 3m, 6m, 1y, 3y, 5y
  final DateTime? targetDate;
  final String? plan;
  final int progress;
  final String status;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VisionGoal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.category,
    required this.duration,
    this.targetDate,
    this.plan,
    required this.progress,
    required this.status,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VisionGoal.fromJson(Map<String, dynamic> json) {
    return VisionGoal(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      duration: json['duration'],
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date']) : null,
      plan: json['plan'],
      progress: json['progress'] ?? 0,
      status: json['status'] ?? 'not_started',
      isFavorite: json['is_favorite'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'duration': duration,
      'target_date': targetDate?.toIso8601String().split('T')[0],
      'plan': plan,
      'progress': progress,
      'status': status,
      'is_favorite': isFavorite,
    };
  }

  @override
  List<Object?> get props => [id, userId, title, description, category, duration, targetDate, plan, progress, status, isFavorite, createdAt, updatedAt];
}
