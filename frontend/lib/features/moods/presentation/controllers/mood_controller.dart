import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:chronicle/features/moods/domain/models/mood_entry.dart';
import 'package:chronicle/features/moods/data/repositories/mood_repository_impl.dart';

class MoodState extends Equatable {
  final bool isLoading;
  final List<MoodEntry> moods;
  
  const MoodState({
    this.isLoading = false,
    this.moods = const [],
  });

  String get mostFrequentMood {
    if (moods.isEmpty) return 'neutral';
    final counts = <String, int>{};
    for (final m in moods) {
      counts[m.mood] = (counts[m.mood] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  MoodState copyWith({bool? isLoading, List<MoodEntry>? moods}) {
    return MoodState(
      isLoading: isLoading ?? this.isLoading,
      moods: moods ?? this.moods,
    );
  }

  @override List<Object?> get props => [isLoading, moods];
}

final moodRepositoryProvider = Provider((ref) {
  return MoodRepositoryImpl(MoodRemoteDatasourceImpl(Supabase.instance.client));
});

class MoodController extends Notifier<MoodState> {
  late final MoodRepositoryImpl _repository;

  @override
  MoodState build() {
    _repository = ref.watch(moodRepositoryProvider) as MoodRepositoryImpl;
    _loadMoods();
    return const MoodState();
  }

  Future<void> _loadMoods() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await _repository.getMoods();
      state = state.copyWith(isLoading: false, moods: results);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logMood(String mood, String? note) async {
    final entry = MoodEntry(
      id: '',
      userId: '',
      mood: mood,
      note: note,
      logDate: DateTime.now(),
    );
    await _repository.upsertMood(entry);
    _loadMoods();
  }

  Future<void> deleteMood(String id) async {
    await _repository.deleteMood(id);
    _loadMoods();
  }
}

final moodControllerProvider = NotifierProvider<MoodController, MoodState>(MoodController.new);
