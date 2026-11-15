import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:chronicle/features/first_times/domain/models/first_time_experience.dart';
import 'package:chronicle/features/first_times/data/repositories/first_time_repository_impl.dart';

class FirstTimeState extends Equatable {
  final bool isLoading;
  final List<FirstTimeExperience> experiences;
  
  const FirstTimeState({
    this.isLoading = false,
    this.experiences = const [],
  });

  FirstTimeState copyWith({bool? isLoading, List<FirstTimeExperience>? experiences}) {
    return FirstTimeState(
      isLoading: isLoading ?? this.isLoading,
      experiences: experiences ?? this.experiences,
    );
  }

  @override List<Object?> get props => [isLoading, experiences];
}

class FirstTimeController extends Notifier<FirstTimeState> {
  late final FirstTimeRepositoryImpl _repository;

  @override
  FirstTimeState build() {
    _repository = FirstTimeRepositoryImpl(FirstTimeRemoteDatasourceImpl(Supabase.instance.client));
    _loadFirstTimes();
    return const FirstTimeState();
  }

  Future<void> _loadFirstTimes() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await _repository.getFirstTimes();
      state = state.copyWith(isLoading: false, experiences: results);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> createExperience(FirstTimeExperience experience) async {
    await _repository.createFirstTime(experience);
    _loadFirstTimes();
  }

  /// Removes the entry immediately (a swiped card must leave the list),
  /// then deletes it; restores it if the delete fails.
  Future<void> deleteExperience(String id) async {
    final previous = state.experiences;
    state = state.copyWith(experiences: previous.where((e) => e.id != id).toList());
    try {
      await _repository.deleteFirstTime(id);
    } catch (_) {
      state = state.copyWith(experiences: previous);
    }
  }
}

final firstTimeControllerProvider = NotifierProvider<FirstTimeController, FirstTimeState>(FirstTimeController.new);
