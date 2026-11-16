import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:chronicle/core/utils/db_time.dart';

/// Status of one hydration slot.
enum HydrationStatus {
  pending('PENDING'),
  done('DONE'),
  skipped('SKIPPED');

  final String key;
  const HydrationStatus(this.key);

  static HydrationStatus fromKey(String? key) =>
      values.where((s) => s.key == key).firstOrNull ?? HydrationStatus.pending;
}

/// One scheduled glass of water on a given day. Slots without a stored log
/// are generated client-side with an empty [id] and [HydrationStatus.pending].
class HydrationReminder extends Equatable {
  final String id;
  final DateTime logDate;
  final DateTime logTime;
  final HydrationStatus status;

  const HydrationReminder({
    required this.id,
    required this.logDate,
    required this.logTime,
    required this.status,
  });

  bool get isStored => id.isNotEmpty;

  /// `HH:mm` — identifies the slot within its day.
  String get slotKey => DbTime.time(TimeOfDay.fromDateTime(logTime));

  factory HydrationReminder.fromJson(Map<String, dynamic> json) {
    return HydrationReminder(
      id: json['id'] as String? ?? '',
      logDate: DateTime.parse(json['log_date'] as String),
      logTime: DbTime.decode(json['log_time'] as String),
      status: HydrationStatus.fromKey(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson(String userId) => {
        'user_id': userId,
        'log_date': DbTime.date(logDate),
        'log_time': DbTime.encode(logTime),
        'status': status.key,
      };

  HydrationReminder withStatus(HydrationStatus next, {String? id}) => HydrationReminder(
        id: id ?? this.id,
        logDate: logDate,
        logTime: logTime,
        status: next,
      );

  @override
  List<Object?> get props => [id, logDate, logTime, status];
}

/// One sleep session. [endTime] is null while the user is still asleep.
class SleepRecord extends Equatable {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;

  const SleepRecord({required this.id, required this.startTime, this.endTime});

  bool get isRecording => endTime == null;

  Duration? get duration => endTime?.difference(startTime);

  /// The night a session belongs to is the day you woke up.
  DateTime? get wakeDay => endTime == null ? null : DateTime(endTime!.year, endTime!.month, endTime!.day);

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    final end = json['sleep_end'] as String?;
    return SleepRecord(
      id: json['id'] as String,
      startTime: DbTime.decode(json['sleep_start'] as String),
      endTime: end == null ? null : DbTime.decode(end),
    );
  }

  @override
  List<Object?> get props => [id, startTime, endTime];
}

/// Exercise / meditation check-ins for one day.
class ActivityLog extends Equatable {
  final String id;
  final DateTime logDate;
  final bool exerciseDone;
  final bool meditationDone;
  final String? notes;

  const ActivityLog({
    required this.id,
    required this.logDate,
    this.exerciseDone = false,
    this.meditationDone = false,
    this.notes,
  });

  factory ActivityLog.empty(DateTime day) => ActivityLog(id: '', logDate: day);

  bool get isStored => id.isNotEmpty;

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      exerciseDone: json['exercise_done'] as bool? ?? false,
      meditationDone: json['meditation_done'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  ActivityLog copyWith({String? id, bool? exerciseDone, bool? meditationDone, String? notes}) => ActivityLog(
        id: id ?? this.id,
        logDate: logDate,
        exerciseDone: exerciseDone ?? this.exerciseDone,
        meditationDone: meditationDone ?? this.meditationDone,
        notes: notes ?? this.notes,
      );

  @override
  List<Object?> get props => [id, logDate, exerciseDone, meditationDone, notes];
}

/// Per-user health preferences (`health_settings`).
class HealthSettings extends Equatable {
  static const defaultStart = TimeOfDay(hour: 6, minute: 0);
  static const defaultEnd = TimeOfDay(hour: 23, minute: 59);
  static const intervalOptions = [30, 45, 60, 90, 120];
  static const minSleepGoal = 4;
  static const maxSleepGoal = 12;

  final TimeOfDay hydrationStart;
  final TimeOfDay hydrationEnd;
  final int hydrationIntervalMinutes;
  final int sleepGoalHours;
  final bool notificationsEnabled;

  const HealthSettings({
    this.hydrationStart = defaultStart,
    this.hydrationEnd = defaultEnd,
    this.hydrationIntervalMinutes = 30,
    this.sleepGoalHours = 8,
    this.notificationsEnabled = true,
  });

  factory HealthSettings.fromJson(Map<String, dynamic> json) {
    final interval = (json['hydration_interval_minutes'] as num?)?.toInt() ?? 30;
    return HealthSettings(
      hydrationStart: DbTime.parseTime(json['hydration_start_time'] as String?, defaultStart),
      hydrationEnd: DbTime.parseTime(json['hydration_end_time'] as String?, defaultEnd),
      hydrationIntervalMinutes: interval < 15 ? 30 : interval,
      sleepGoalHours: (json['sleep_goal_hours'] as num?)?.toInt() ?? 8,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson(String userId) => {
        'user_id': userId,
        'hydration_start_time': DbTime.time(hydrationStart),
        'hydration_end_time': DbTime.time(hydrationEnd),
        'hydration_interval_minutes': hydrationIntervalMinutes,
        'sleep_goal_hours': sleepGoalHours,
        'notifications_enabled': notificationsEnabled,
      };

  HealthSettings copyWith({
    TimeOfDay? hydrationStart,
    TimeOfDay? hydrationEnd,
    int? hydrationIntervalMinutes,
    int? sleepGoalHours,
    bool? notificationsEnabled,
  }) =>
      HealthSettings(
        hydrationStart: hydrationStart ?? this.hydrationStart,
        hydrationEnd: hydrationEnd ?? this.hydrationEnd,
        hydrationIntervalMinutes: hydrationIntervalMinutes ?? this.hydrationIntervalMinutes,
        sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  /// Clock times of the day's water slots: from [hydrationStart] to
  /// [hydrationEnd] inclusive, every [hydrationIntervalMinutes].
  List<TimeOfDay> get hydrationSlotTimes {
    final start = hydrationStart.hour * 60 + hydrationStart.minute;
    final end = hydrationEnd.hour * 60 + hydrationEnd.minute;
    if (end < start) return const [];
    return [
      for (var m = start; m <= end; m += hydrationIntervalMinutes) TimeOfDay(hour: m ~/ 60, minute: m % 60),
    ];
  }

  @override
  List<Object?> get props => [hydrationStart, hydrationEnd, hydrationIntervalMinutes, sleepGoalHours, notificationsEnabled];
}
