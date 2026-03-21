import 'package:chronicle/features/moods/domain/models/mood_entry.dart';

abstract class MoodRemoteDatasource {
  Future<List<MoodEntry>> getMoods();
  Future<void> upsertMood(MoodEntry mood);
  Future<void> deleteMood(String id);
}
