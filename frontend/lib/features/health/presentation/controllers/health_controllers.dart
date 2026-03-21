import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';

class HydrationState extends Equatable {
  final bool isLoading;
  final List<HydrationReminder> reminders;
  const HydrationState({this.isLoading = false, this.reminders = const []});
  
  double get hydrationPercentage {
    if (reminders.isEmpty) return 0;
    final done = reminders.where((r) => r.status == 'DONE').length;
    return (done / reminders.length) * 100;
  }
  
  int get doneReminders => reminders.where((r) => r.status == 'DONE').length;

  @override List<Object?> get props => [isLoading, reminders];
}

class HydrationController extends Notifier<HydrationState> {
  @override
  HydrationState build() {
    return HydrationState(reminders: List.generate(10, (i) => HydrationReminder(
      id: i.toString(), 
      status: 'PENDING',
      scheduledTime: DateTime.now(),
    )));
  }

  void markAsDone(String id) {
    state = HydrationState(
      isLoading: state.isLoading,
      reminders: state.reminders.map((r) => r.id == id ? HydrationReminder(id: id, status: 'DONE', scheduledTime: r.scheduledTime) : r).toList(),
    );
  }

  void markAsSkipped(String id) {
    state = HydrationState(
      isLoading: state.isLoading,
      reminders: state.reminders.map((r) => r.id == id ? HydrationReminder(id: id, status: 'SKIPPED', scheduledTime: r.scheduledTime) : r).toList(),
    );
  }
}

final hydrationControllerProvider = NotifierProvider<HydrationController, HydrationState>(HydrationController.new);

// Sleep
class SleepState extends Equatable {
  final bool isLoading;
  final bool isSleeping;
  final List<SleepRecord> entries;
  const SleepState({this.isLoading = false, this.isSleeping = false, this.entries = const []});

  @override List<Object?> get props => [isLoading, isSleeping, entries];
}

class SleepController extends Notifier<SleepState> {
  @override
  SleepState build() {
    return SleepState(entries: [
      SleepRecord(id: '1', startTime: DateTime.now().subtract(const Duration(days: 1)), endTime: DateTime.now().subtract(const Duration(hours: 1)), duration: const Duration(hours: 7, minutes: 30)),
    ]);
  }

  void startSleep() {
    state = SleepState(isLoading: state.isLoading, isSleeping: true, entries: state.entries);
  }

  void wakeUp() {
    final entry = SleepRecord(id: DateTime.now().toString(), startTime: DateTime.now().subtract(const Duration(hours: 8)), endTime: DateTime.now(), duration: const Duration(hours: 8));
    state = SleepState(isLoading: state.isLoading, isSleeping: false, entries: [entry, ...state.entries]);
  }
}

final sleepControllerProvider = NotifierProvider<SleepController, SleepState>(SleepController.new);
