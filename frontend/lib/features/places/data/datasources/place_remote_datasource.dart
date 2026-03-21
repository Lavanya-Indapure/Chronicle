import 'package:chronicle/features/places/domain/models/place_visited.dart';

abstract class PlaceRemoteDatasource {
  Future<List<PlaceVisited>> getPlaces();
  Future<void> createPlace(PlaceVisited place);
  Future<void> updatePlace(String id, PlaceVisited place);
  Future<void> deletePlace(String id);
}
