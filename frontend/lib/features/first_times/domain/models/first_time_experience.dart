import 'package:equatable/equatable.dart';

class FirstTimeExperience extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime logDate;
  final String? emotion;
  final int? rating;
  final String? location;
  final List<String> photos;

  const FirstTimeExperience({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.logDate,
    this.emotion,
    this.rating,
    this.location,
    this.photos = const [],
  });

  factory FirstTimeExperience.fromJson(Map<String, dynamic> json) {
    return FirstTimeExperience(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      logDate: json['log_date'] != null ? DateTime.parse(json['log_date']) : DateTime.now(),
      emotion: json['emotion'],
      rating: json['rating'],
      location: json['location'],
      photos: List<String>.from(json['photos'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'log_date': logDate.toIso8601String().split('T')[0],
      'emotion': emotion,
      'rating': rating,
      'location': location,
      'photos': photos,
    };
  }

  @override
  List<Object?> get props => [id, userId, title, description, logDate, emotion, rating, location, photos];
}
