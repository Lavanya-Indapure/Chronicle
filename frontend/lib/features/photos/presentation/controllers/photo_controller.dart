import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:chronicle/features/photos/domain/models/photo.dart';
import 'package:chronicle/features/photos/domain/repositories/photo_repository.dart';
import 'package:chronicle/features/photos/data/repositories/photo_repository_impl.dart';
import 'package:chronicle/features/photos/data/datasources/photo_remote_datasource.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class PhotoState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<Photo> photos;

  const PhotoState({
    this.isLoading = false,
    this.errorMessage,
    this.photos = const [],
  });

  PhotoState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Photo>? photos,
  }) {
    return PhotoState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      photos: photos ?? this.photos,
    );
  }

  /// Photos grouped by the month they were taken, newest month (and photo)
  /// first. Keys are the first day of each month.
  Map<DateTime, List<Photo>> get photosByMonth {
    final sorted = [...photos]..sort((a, b) => b.photoDate.compareTo(a.photoDate));
    final groups = <DateTime, List<Photo>>{};
    for (final p in sorted) {
      groups.putIfAbsent(DateTime(p.photoDate.year, p.photoDate.month), () => []).add(p);
    }
    return groups;
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, photos];
}

class PhotoController extends Notifier<PhotoState> {
  late final PhotoRepository _repository;

  @override
  PhotoState build() {
    final client = Supabase.instance.client;
    final datasource = PhotoRemoteDatasource(client);
    _repository = PhotoRepositoryImpl(datasource);
    
    // Proactively load photos
    Future.microtask(() => loadPhotos());
    
    return const PhotoState();
  }

  Future<void> loadPhotos() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final photos = await _repository.getPhotos();
      state = state.copyWith(photos: photos, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<bool> uploadPhoto({
    required File file,
    String? caption,
    required DateTime date,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.uploadPhoto(file: file, caption: caption, date: date);
      await loadPhotos();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  /// Removes the photo from the grid immediately, then deletes it; restores
  /// it (and sets [PhotoState.errorMessage]) if the delete fails.
  Future<bool> deletePhoto(Photo photo) async {
    final previous = state.photos;
    state = state.copyWith(photos: previous.where((p) => p.id != photo.id).toList());
    try {
      await _repository.deletePhoto(photo);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(photos: previous, errorMessage: e.message);
      return false;
    }
  }
}

final photoControllerProvider = NotifierProvider<PhotoController, PhotoState>(PhotoController.new);
