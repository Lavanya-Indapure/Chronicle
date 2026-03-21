import 'package:equatable/equatable.dart';

class PlaceVisited extends Equatable {
  final String id;
  final String userId;
  final String placeName;
  final String? city;
  final DateTime visitDate;
  final String? description;
  final int? rating;
  final List<String> photos;

  const PlaceVisited({
    required this.id,
    required this.userId,
    required this.placeName,
    this.city,
    required this.visitDate,
    this.description,
    this.rating,
    this.photos = const [],
  });

  factory PlaceVisited.fromJson(Map<String, dynamic> json) {
    return PlaceVisited(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      placeName: json['place_name'] ?? '',
      city: json['city'],
      visitDate: json['visit_date'] != null ? DateTime.parse(json['visit_date']) : DateTime.now(),
      description: json['description'],
      rating: json['rating'],
      photos: List<String>.from(json['photos'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_name': placeName,
      'city': city,
      'visit_date': visitDate.toIso8601String().split('T')[0],
      'description': description,
      'rating': rating,
      'photos': photos,
    };
  }

  @override
  List<Object?> get props => [id, userId, placeName, city, visitDate, description, rating, photos];
}
