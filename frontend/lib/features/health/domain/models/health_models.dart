import 'package:equatable/equatable.dart';

class HydrationReminder extends Equatable {
  final String id;
  final String userId;
  final DateTime logDate; // The day this belongs to
  final DateTime logTime; // The specific scheduled/log time
  final String status; // DONE, SKIPPED, PENDING

  const HydrationReminder({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.logTime,
    required this.status,
  });

  factory HydrationReminder.fromJson(Map<String, dynamic> json) {
    return HydrationReminder(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      logDate: DateTime.parse(json['log_date']),
      logTime: DateTime.parse(json['log_time']),
      status: json['status'] ?? 'PENDING',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'log_date': logDate.toIso8601String().split('T')[0],
      'log_time': logTime.toIso8601String(),
      'status': status,
    };
  }

  @override
  List<Object?> get props => [id, userId, logDate, logTime, status];
}

class SleepRecord extends Equatable {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;

  const SleepRecord({
    required this.id,
    required this.startTime,
    this.endTime,
    this.duration,
  });

  bool get isRecording => endTime == null;

  @override
  List<Object?> get props => [id, startTime, endTime, duration];
}

class ActivityRecord extends Equatable {
  final String id;
  final String type;
  final int durationMinutes;
  final DateTime date;

  const ActivityRecord({
    required this.id,
    required this.type,
    required this.durationMinutes,
    required this.date,
  });

  @override
  List<Object?> get props => [id, type, durationMinutes, date];
}

class HealthSettings extends Equatable {
  final String userId;
  final String hydrationStartTime; // '06:00'
  final String hydrationEndTime;   // '23:59'
  final int hydrationIntervalMinutes;
  final int sleepGoalHours;
  final bool notificationsEnabled;

  const HealthSettings({
    required this.userId,
    this.hydrationStartTime = '06:00',
    this.hydrationEndTime = '23:59',
    this.hydrationIntervalMinutes = 30,
    this.sleepGoalHours = 8,
    this.notificationsEnabled = true,
  });

  factory HealthSettings.fromJson(Map<String, dynamic> json) {
    return HealthSettings(
      userId: json['user_id'] ?? '',
      hydrationStartTime: json['hydration_start_time'] ?? '06:00',
      hydrationEndTime: json['hydration_end_time'] ?? '23:59',
      hydrationIntervalMinutes: json['hydration_interval_minutes'] ?? 30,
      sleepGoalHours: json['sleep_goal_hours'] ?? 8,
      notificationsEnabled: json['notifications_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'hydration_start_time': hydrationStartTime,
      'hydration_end_time': hydrationEndTime,
      'hydration_interval_minutes': hydrationIntervalMinutes,
      'sleep_goal_hours': sleepGoalHours,
      'notifications_enabled': notificationsEnabled,
    };
  }

  @override
  List<Object?> get props => [userId, hydrationStartTime, hydrationEndTime, hydrationIntervalMinutes, sleepGoalHours, notificationsEnabled];
}
