import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class RestaurantRemoteDatasource {
  final SupabaseClient _client;

  RestaurantRemoteDatasource(this._client);

  Future<List<Restaurant>> getRestaurants() async {
    try {
      final response = await _client
          .from('restaurants')
          .select('*, restaurant_photos(*)')
          .order('updated_at', ascending: false);
      
      return (response as List).map((json) => Restaurant.fromJson(json)).toList();
    } catch (e) {
      throw AppException('Failed to fetch restaurants: $e');
    }
  }

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
    try {
      final userId = _client.auth.currentUser!.id;

      // 1. Insert Restaurant (Aggregate)
      final restaurantJson = await _client.from('restaurants').insert({
        'user_id': userId,
        'name': name,
        'address': address,
        'rating': rating,
        'latest_bill_amount': billAmount,
        'latest_food_items': foodItems,
        'latest_notes': notes,
        'is_favorite': isFavorite,
        'visit_count': 1,
      }).select().single();

      final restaurantId = restaurantJson['id'];

      // 2. Insert First Visit
      final visitJson = await _client.from('restaurant_visits').insert({
        'restaurant_id': restaurantId,
        'user_id': userId,
        'bill_amount': billAmount,
        'food_items': foodItems,
        'rating': rating,
        'notes': notes,
      }).select().single();

      final visitId = visitJson['id'];

      // 3. Upload Photos
      if (photos.isNotEmpty) {
        for (final file in photos) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
          final storagePath = '$userId/$fileName';
          
          await _client.storage.from('restaurants').upload(storagePath, file);
          final imageUrl = _client.storage.from('restaurants').getPublicUrl(storagePath);

          await _client.from('restaurant_photos').insert({
            'restaurant_id': restaurantId,
            'visit_id': visitId,
            'user_id': userId,
            'storage_path': storagePath,
            'image_url': imageUrl,
          });
        }
      }

      // 4. Return complete object
      final finalResponse = await _client
          .from('restaurants')
          .select('*, restaurant_photos(*)')
          .eq('id', restaurantId)
          .single();
          
      return Restaurant.fromJson(finalResponse);
    } catch (e) {
      throw AppException('Failed to create restaurant: $e');
    }
  }

  Future<Restaurant> logRevisit({
    required String restaurantId,
    required double rating,
    double? billAmount,
    String? foodItems,
    String? notes,
    List<File> photos = const [],
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;

      // 1. Insert Visit
      final visitJson = await _client.from('restaurant_visits').insert({
        'restaurant_id': restaurantId,
        'user_id': userId,
        'bill_amount': billAmount,
        'food_items': foodItems,
        'rating': rating,
        'notes': notes,
      }).select().single();

      final visitId = visitJson['id'];

      // 2. Upload Photos
      if (photos.isNotEmpty) {
        for (final file in photos) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
          final storagePath = '$userId/$fileName';
          
          await _client.storage.from('restaurants').upload(storagePath, file);
          final imageUrl = _client.storage.from('restaurants').getPublicUrl(storagePath);

          await _client.from('restaurant_photos').insert({
            'restaurant_id': restaurantId,
            'visit_id': visitId,
            'user_id': userId,
            'storage_path': storagePath,
            'image_url': imageUrl,
          });
        }
      }

      // 3. Update Aggregate Restaurant Table
      await _client.rpc('increment_restaurant_visit', params: {
        'row_id': restaurantId,
        'new_rating': rating,
        'new_bill': billAmount,
        'new_food': foodItems,
        'new_notes': notes,
      });

      // 4. Return complete object
      final finalResponse = await _client
          .from('restaurants')
          .select('*, restaurant_photos(*)')
          .eq('id', restaurantId)
          .single();
          
      return Restaurant.fromJson(finalResponse);
    } catch (e) {
      throw AppException('Failed to log revisit: $e');
    }
  }

  Future<void> toggleFavorite(String id, bool currentStatus) async {
    try {
      await _client.from('restaurants').update({'is_favorite': !currentStatus}).eq('id', id);
    } catch (e) {
      throw AppException('Failed to toggle favorite: $e');
    }
  }

  Future<List<RestaurantVisit>> getVisitHistory(String restaurantId) async {
    try {
      final response = await _client
          .from('restaurant_visits')
          .select('*, restaurant_photos(*)')
          .eq('restaurant_id', restaurantId)
          .order('visit_date', ascending: false);
      
      return (response as List).map((json) => RestaurantVisit.fromJson(json)).toList();
    } catch (e) {
      throw AppException('Failed to fetch visit history: $e');
    }
  }
}
