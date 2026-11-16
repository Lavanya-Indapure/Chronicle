import 'package:equatable/equatable.dart';
import 'package:chronicle/core/utils/tags.dart';

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
  final List<String> tags;

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
    this.tags = const [],
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
      tags: TagUtils.fromJson(json['tags']),
    );
  }

  /// [previousTags]: the stored tags when updating, so clearing them is
  /// written while untagged rows omit the column (see [TagUtils.forWrite]).
  Map<String, dynamic> toJson({List<String> previousTags = const []}) {
    return {
      'name': name,
      'watch_date': watchDate.toIso8601String().split('T')[0],
      'platform': platform,
      'rating': rating,
      'cost': cost,
      'comments': comments,
      'takeaways': takeaways,
      'tags': ?TagUtils.forWrite(tags, previous: previousTags),
    };
  }

  @override
  List<Object?> get props => [id, userId, name, watchDate, platform, rating, cost, comments, takeaways, tags];
}
