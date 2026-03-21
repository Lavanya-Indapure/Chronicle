import 'package:equatable/equatable.dart';

class HydrationReminder extends Equatable {
  final String id;
  final String status; // DONE, SKIPPED, PENDING
  final DateTime scheduledTime;

  const HydrationReminder({
    required this.id,
    required this.status,
    required this.scheduledTime,
  });

  @override
  List<Object?> get props => [id, status, scheduledTime];
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
