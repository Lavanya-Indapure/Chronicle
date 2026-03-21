import 'dart:io';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';
import 'package:chronicle/features/restaurants/domain/repositories/restaurant_repository.dart';
import 'package:chronicle/features/restaurants/data/datasources/restaurant_remote_datasource.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final RestaurantRemoteDatasource _datasource;

  RestaurantRepositoryImpl(this._datasource);

  @override
  Future<List<Restaurant>> getRestaurants() async {
    return await _datasource.getRestaurants();
  }

  @override
  Future<Restaurant> createRestaurant({
    required String name,
    required String address,
    required double rating,
    double? billAmount,
    String? foodItems,
    String? notes,
    List<File> photos = const [],
    bool isFavorite = false,
  }) async {
    return await _datasource.createRestaurant(
      name: name,
      address: address,
      rating: rating,
      billAmount: billAmount,
      foodItems: foodItems,
      notes: notes,
      photos: photos,
      isFavorite: isFavorite,
    );
  }

  @override
  Future<Restaurant> logRevisit({
    required String restaurantId,
    required double rating,
    double? billAmount,
    String? foodItems,
    String? notes,
    List<File> photos = const [],
  }) async {
    return await _datasource.logRevisit(
      restaurantId: restaurantId,
      rating: rating,
      billAmount: billAmount,
      foodItems: foodItems,
      notes: notes,
      photos: photos,
    );
  }

  @override
  Future<void> toggleFavorite(String id, bool currentStatus) async {
    await _datasource.toggleFavorite(id, currentStatus);
  }

  @override
  Future<List<RestaurantVisit>> getVisitHistory(String restaurantId) async {
    return await _datasource.getVisitHistory(restaurantId);
  }
}
