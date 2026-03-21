import 'package:chronicle/features/first_times/domain/models/first_time_experience.dart';

abstract class FirstTimeRemoteDatasource {
  Future<List<FirstTimeExperience>> getFirstTimes();
  Future<void> createFirstTime(FirstTimeExperience experience);
  Future<void> updateFirstTime(String id, FirstTimeExperience experience);
  Future<void> deleteFirstTime(String id);
}
