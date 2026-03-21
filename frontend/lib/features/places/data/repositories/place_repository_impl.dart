import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/places/domain/models/place_visited.dart';
import 'package:chronicle/features/places/domain/repositories/place_repository.dart';
import 'package:chronicle/features/places/data/datasources/place_remote_datasource.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class PlaceRemoteDatasourceImpl implements PlaceRemoteDatasource {
  final SupabaseClient _client;
  PlaceRemoteDatasourceImpl(this._client);

  @override
  Future<List<PlaceVisited>> getPlaces() async {
    try {
      final response = await _client.from('places_visited').select().order('visit_date', ascending: false);
      return (response as List).map((json) => PlaceVisited.fromJson(json)).toList();
    } catch (e) {
      throw AppException('Failed to fetch places: $e');
    }
  }

  @override
  Future<void> createPlace(PlaceVisited place) async {
    try {
      final data = place.toJson();
      data['user_id'] = _client.auth.currentUser!.id;
      await _client.from('places_visited').insert(data);
    } catch (e) {
      throw AppException('Failed to create place: $e');
    }
  }

  @override
  Future<void> updatePlace(String id, PlaceVisited place) async {
    try {
      await _client.from('places_visited').update(place.toJson()).eq('id', id);
    } catch (e) {
      throw AppException('Failed to update place: $e');
    }
  }

  @override
  Future<void> deletePlace(String id) async {
    try {
      await _client.from('places_visited').delete().eq('id', id);
    } catch (e) {
      throw AppException('Failed to delete place: $e');
    }
  }
}

class PlaceRepositoryImpl implements PlaceRepository {
  final PlaceRemoteDatasource _datasource;
  PlaceRepositoryImpl(this._datasource);

  @override Future<List<PlaceVisited>> getPlaces() => _datasource.getPlaces();
  @override Future<void> createPlace(PlaceVisited place) => _datasource.createPlace(place);
  @override Future<void> updatePlace(String id, PlaceVisited place) => _datasource.updatePlace(id, place);
  @override Future<void> deletePlace(String id) => _datasource.deletePlace(id);
}
