import 'package:equatable/equatable.dart';

class Movie extends Equatable {
  final String id;
  final String userId;
  final String name;
  final DateTime watchDate;
  final String platform; // 'theatre', 'mobile-laptop'
  final int rating;
  final double? cost;
  final String? comments;
  final String? takeaways;

  const Movie({
    required this.id,
    required this.userId,
    required this.name,
    required this.watchDate,
    required this.platform,
    required this.rating,
    this.cost,
    this.comments,
    this.takeaways,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      watchDate: DateTime.parse(json['watch_date']),
      platform: json['platform'],
      rating: json['rating'],
      cost: (json['cost'] as num?)?.toDouble(),
      comments: json['comments'],
      takeaways: json['takeaways'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'watch_date': watchDate.toIso8601String().split('T')[0],
      'platform': platform,
      'rating': rating,
      'cost': cost,
      'comments': comments,
      'takeaways': takeaways,
    };
  }

  @override
  List<Object?> get props => [id, userId, name, watchDate, platform, rating, cost, comments, takeaways];
}
