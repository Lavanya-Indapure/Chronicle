import 'dart:io';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';

abstract class RestaurantRepository {
  Future<List<Restaurant>> getRestaurants();
  Future<Restaurant> createRestaurant({
    required String name,
    required String address,
    required double rating,
    double? billAmount,
    String? foodItems,
    String? notes,
    List<File> photos,
    bool isFavorite,
  });
  Future<Restaurant> logRevisit({
    required String restaurantId,
    required double rating,
    double? billAmount,
    String? foodItems,
    String? notes,
    List<File> photos,
  });
  Future<void> toggleFavorite(String id, bool currentStatus);
  Future<List<RestaurantVisit>> getVisitHistory(String restaurantId);
}
