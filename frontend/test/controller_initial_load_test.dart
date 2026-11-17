import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronicle/features/learnings/data/datasources/learning_remote_datasource.dart';
import 'package:chronicle/features/learnings/data/repositories/learning_repository_impl.dart';
import 'package:chronicle/features/learnings/domain/models/learning.dart';
import 'package:chronicle/features/learnings/presentation/controllers/learning_controller.dart';
import 'package:chronicle/features/moods/data/datasources/mood_remote_datasource.dart';
import 'package:chronicle/features/moods/data/repositories/mood_repository_impl.dart';
import 'package:chronicle/features/moods/domain/models/mood_entry.dart';
import 'package:chronicle/features/moods/presentation/controllers/mood_controller.dart';
import 'package:chronicle/features/places/data/datasources/place_remote_datasource.dart';
import 'package:chronicle/features/places/data/repositories/place_repository_impl.dart';
import 'package:chronicle/features/places/domain/models/place_visited.dart';
import 'package:chronicle/features/places/presentation/controllers/place_controller.dart';

// Regression: these controllers used to start loading synchronously inside
// build(), which reads `state` before it exists. Riverpod reports that as an
// error inside the async loader, so the fetch never ran and the screens
// opened empty. The widget tests override build(), so only this catches it.

class _PlaceSource implements PlaceRemoteDatasource {
  int fetches = 0;

  @override
  Future<List<PlaceVisited>> getPlaces() async {
    fetches++;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MoodSource implements MoodRemoteDatasource {
  int fetches = 0;

  @override
  Future<List<MoodEntry>> getMoods() async {
    fetches++;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LearningSource implements LearningRemoteDatasource {
  int fetches = 0;

  @override
  Future<List<Learning>> getLearnings() async {
    fetches++;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('places load when the controller is first built', () async {
    final source = _PlaceSource();
    final container = ProviderContainer(
      overrides: [placeRepositoryProvider.overrideWithValue(PlaceRepositoryImpl(source))],
    );
    addTearDown(container.dispose);

    container.read(placeControllerProvider);
    await _settle();

    expect(source.fetches, 1);
    expect(container.read(placeControllerProvider).isLoading, isFalse);
  });

  test('moods load when the controller is first built', () async {
    final source = _MoodSource();
    final container = ProviderContainer(
      overrides: [moodRepositoryProvider.overrideWithValue(MoodRepositoryImpl(source))],
    );
    addTearDown(container.dispose);

    container.read(moodControllerProvider);
    await _settle();

    expect(source.fetches, 1);
    expect(container.read(moodControllerProvider).isLoading, isFalse);
  });

  test('learnings load when the controller is first built', () async {
    final source = _LearningSource();
    final container = ProviderContainer(
      overrides: [learningRepositoryProvider.overrideWithValue(LearningRepositoryImpl(source))],
    );
    addTearDown(container.dispose);

    container.read(learningControllerProvider);
    await _settle();

    expect(source.fetches, 1);
    expect(container.read(learningControllerProvider).isLoading, isFalse);
  });
}
