import 'package:equatable/equatable.dart';

class Restaurant extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String address;
  final int visitCount;
  final bool isFavorite;
  final double rating;
  final double? latestBillAmount;
  final String? latestFoodItems;
  final String? latestNotes;
  final List<RestaurantPhoto> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Restaurant({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.visitCount,
    required this.isFavorite,
    required this.rating,
    this.latestBillAmount,
    this.latestFoodItems,
    this.latestNotes,
    this.photos = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      address: json['address'],
      visitCount: json['visit_count'] ?? 1,
      isFavorite: json['is_favorite'] ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      latestBillAmount: (json['latest_bill_amount'] as num?)?.toDouble(),
      latestFoodItems: json['latest_food_items'],
      latestNotes: json['latest_notes'],
      photos: (json['restaurant_photos'] as List?)
              ?.map((p) => RestaurantPhoto.fromJson(p))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        address,
        visitCount,
        isFavorite,
        rating,
        latestBillAmount,
        latestFoodItems,
        latestNotes,
        photos,
        createdAt,
        updatedAt
      ];
}

class RestaurantVisit extends Equatable {
  final String id;
  final String restaurantId;
  final DateTime visitDate;
  final double? billAmount;
  final String? foodItems;
  final double? rating;
  final String? notes;
  final List<RestaurantPhoto> photos;

  const RestaurantVisit({
    required this.id,
    required this.restaurantId,
    required this.visitDate,
    this.billAmount,
    this.foodItems,
    this.rating,
    this.notes,
    this.photos = const [],
  });

  factory RestaurantVisit.fromJson(Map<String, dynamic> json) {
    return RestaurantVisit(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      visitDate: DateTime.parse(json['visit_date']),
      billAmount: (json['bill_amount'] as num?)?.toDouble(),
      foodItems: json['food_items'],
      rating: (json['rating'] as num?)?.toDouble(),
      notes: json['notes'],
      photos: (json['restaurant_photos'] as List?)
              ?.map((p) => RestaurantPhoto.fromJson(p))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [id, restaurantId, visitDate, billAmount, foodItems, rating, notes, photos];
}

class RestaurantPhoto extends Equatable {
  final String id;
  final String restaurantId;
  final String? visitId;
  final String storagePath;
  final String imageUrl;

  const RestaurantPhoto({
    required this.id,
    required this.restaurantId,
    this.visitId,
    required this.storagePath,
    required this.imageUrl,
  });

  factory RestaurantPhoto.fromJson(Map<String, dynamic> json) {
    return RestaurantPhoto(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      visitId: json['visit_id'],
      storagePath: json['storage_path'],
      imageUrl: json['image_url'],
    );
  }

  @override
  List<Object?> get props => [id, restaurantId, visitId, storagePath, imageUrl];
}
