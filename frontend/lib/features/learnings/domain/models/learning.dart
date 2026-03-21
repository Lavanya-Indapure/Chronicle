import 'package:equatable/equatable.dart';

class Learning extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? category;
  final String? source;
  final int? usefulnessRating;
  final DateTime logDate;

  const Learning({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.category,
    this.source,
    this.usefulnessRating,
    required this.logDate,
  });

  factory Learning.fromJson(Map<String, dynamic> json) {
    return Learning(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'],
      source: json['source'],
      usefulnessRating: json['usefulness_rating'],
      logDate: json['log_date'] != null ? DateTime.parse(json['log_date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'source': source,
      'usefulness_rating': usefulnessRating,
      'log_date': logDate.toIso8601String().split('T')[0],
    };
  }

  @override
  List<Object?> get props => [id, userId, title, description, category, source, usefulnessRating, logDate];
}
