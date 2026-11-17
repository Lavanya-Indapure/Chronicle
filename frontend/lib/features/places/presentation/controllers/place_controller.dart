import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:chronicle/features/places/domain/models/place_visited.dart';
import 'package:chronicle/features/places/data/repositories/place_repository_impl.dart';

class PlaceState extends Equatable {
  final bool isLoading;
  final List<PlaceVisited> places;
  final String searchQuery;
  
  const PlaceState({
    this.isLoading = false,
    this.places = const [],
    this.searchQuery = '',
  });

  List<PlaceVisited> get filteredPlaces {
    if (searchQuery.isEmpty) return places;
    return places.where((p) => 
      p.placeName.toLowerCase().contains(searchQuery.toLowerCase()) ||
      (p.city?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  PlaceState copyWith({bool? isLoading, List<PlaceVisited>? places, String? searchQuery}) {
    return PlaceState(
      isLoading: isLoading ?? this.isLoading,
      places: places ?? this.places,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override List<Object?> get props => [isLoading, places, searchQuery];
}

final placeRepositoryProvider = Provider((ref) {
  return PlaceRepositoryImpl(PlaceRemoteDatasourceImpl(Supabase.instance.client));
});

class PlaceController extends Notifier<PlaceState> {
  late final PlaceRepositoryImpl _repository;

  @override
  PlaceState build() {
    _repository = ref.watch(placeRepositoryProvider);
    Future.microtask(_loadPlaces);
    return const PlaceState();
  }

  Future<void> _loadPlaces() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await _repository.getPlaces();
      state = state.copyWith(isLoading: false, places: results);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);

  Future<void> addPlace(PlaceVisited place) async {
    await _repository.createPlace(place);
    _loadPlaces();
  }

  /// Removes the entry immediately (a swiped card must leave the list),
  /// then deletes it; restores it if the delete fails.
  Future<void> deletePlace(String id) async {
    final previous = state.places;
    state = state.copyWith(places: previous.where((p) => p.id != id).toList());
    try {
      await _repository.deletePlace(id);
    } catch (_) {
      state = state.copyWith(places: previous);
    }
  }
}

final placeControllerProvider = NotifierProvider<PlaceController, PlaceState>(PlaceController.new);
