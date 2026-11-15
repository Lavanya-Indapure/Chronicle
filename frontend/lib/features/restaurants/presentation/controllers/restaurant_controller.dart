import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';
import 'package:chronicle/features/restaurants/domain/repositories/restaurant_repository.dart';
import 'package:chronicle/features/restaurants/data/repositories/restaurant_repository_impl.dart';
import 'package:chronicle/features/restaurants/data/datasources/restaurant_remote_datasource.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class RestaurantState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<Restaurant> restaurants;
  final String searchQuery;
  final RestaurantFilters filters;

  const RestaurantState({
    this.isLoading = false,
    this.errorMessage,
    this.restaurants = const [],
    this.searchQuery = '',
    this.filters = const RestaurantFilters(),
  });

  RestaurantState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Restaurant>? restaurants,
    String? searchQuery,
    RestaurantFilters? filters,
  }) {
    return RestaurantState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      restaurants: restaurants ?? this.restaurants,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
    );
  }

  List<Restaurant> get filteredRestaurants {
    var result = restaurants.where((r) {
      // Search
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesName = r.name.toLowerCase().contains(query);
        final matchesFood = r.latestFoodItems?.toLowerCase().contains(query) ?? false;
        if (!matchesName && !matchesFood) return false;
      }

      // Filters
      if (filters.onlyFavorites && !r.isFavorite) return false;
      if (filters.minRating != null && r.rating < filters.minRating!) return false;

      return true;
    }).toList();

    // Sorting
    switch (filters.sorting) {
      case RestaurantSorting.latestVisited:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case RestaurantSorting.highestRated:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case RestaurantSorting.mostVisited:
        result.sort((a, b) => b.visitCount.compareTo(a.visitCount));
        break;
    }

    return result;
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, restaurants, searchQuery, filters];
}

enum RestaurantSorting { latestVisited, highestRated, mostVisited }

class RestaurantFilters extends Equatable {
  final bool onlyFavorites;
  final double? minRating;
  final RestaurantSorting sorting;

  const RestaurantFilters({
    this.onlyFavorites = false,
    this.minRating,
    this.sorting = RestaurantSorting.latestVisited,
  });

  RestaurantFilters copyWith({
    bool? onlyFavorites,
    double? minRating,
     RestaurantSorting? sorting,
     bool clearRating = false,
  }) {
    return RestaurantFilters(
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      minRating: clearRating ? null : (minRating ?? this.minRating),
      sorting: sorting ?? this.sorting,
    );
  }

  @override
  List<Object?> get props => [onlyFavorites, minRating, sorting];
}

class RestaurantController extends Notifier<RestaurantState> {
  late final RestaurantRepository _repository;

  @override
  RestaurantState build() {
    final client = Supabase.instance.client;
    final datasource = RestaurantRemoteDatasource(client);
    _repository = RestaurantRepositoryImpl(datasource);
    
    Future.microtask(() => loadRestaurants());
    
    return const RestaurantState();
  }

  Future<void> loadRestaurants() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final restaurants = await _repository.getRestaurants();
      state = state.copyWith(restaurants: restaurants, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Returns false (and sets [RestaurantState.errorMessage]) if saving failed,
  /// so the sheet can stay open instead of closing as if it worked.
  Future<bool> createRestaurant({
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
      await _repository.createRestaurant(
        name: name,
        address: address,
        rating: rating,
        billAmount: billAmount,
        foodItems: foodItems,
        notes: notes,
        photos: photos,
        isFavorite: isFavorite,
      );
      await loadRestaurants();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  /// Returns false (and sets [RestaurantState.errorMessage]) if saving failed.
  Future<bool> logRevisit({
    required String restaurantId,
    required double rating,
    double? billAmount,
    String? foodItems,
    String? notes,
    List<File> photos = const [],
  }) async {
    try {
      await _repository.logRevisit(
        restaurantId: restaurantId,
        rating: rating,
        billAmount: billAmount,
        foodItems: foodItems,
        notes: notes,
        photos: photos,
      );
      await loadRestaurants();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<void> toggleFavorite(Restaurant restaurant) async {
    try {
      await _repository.toggleFavorite(restaurant.id, restaurant.isFavorite);
      await loadRestaurants();
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilters(RestaurantFilters filters) {
    state = state.copyWith(filters: filters);
  }

  Future<List<RestaurantVisit>> getVisitHistory(String id) async {
    try {
      return await _repository.getVisitHistory(id);
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return [];
    }
  }
}

final restaurantControllerProvider = NotifierProvider<RestaurantController, RestaurantState>(RestaurantController.new);
