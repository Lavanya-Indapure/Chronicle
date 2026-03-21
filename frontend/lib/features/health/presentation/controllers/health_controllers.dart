import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';
import 'package:chronicle/features/health/data/repositories/hydration_repository_impl.dart';
import 'package:chronicle/features/health/data/datasources/hydration_remote_datasource_impl.dart';

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

final hydrationRepositoryProvider = Provider((ref) {
  return HydrationRepositoryImpl(HydrationRemoteDatasourceImpl(Supabase.instance.client));
});

class HydrationController extends Notifier<HydrationState> {
  late final HydrationRepositoryImpl _repository;

  @override
  HydrationState build() {
    _repository = ref.watch(hydrationRepositoryProvider) as HydrationRepositoryImpl;
    _loadTodayLogs();
    return const HydrationState(isLoading: true);
  }

  Future<void> _loadTodayLogs() async {
    try {
      final logs = await _repository.getTodayLogs();
      _generateReminders(logs);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void _generateReminders(List<HydrationReminder> logs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Ideal: fetch from settings. Current: 6 AM to 10 PM every 60 mins (17 slots)
    final List<HydrationReminder> reminders = [];
    for (int i = 0; i < 17; i++) {
      final scheduledTime = today.add(Duration(hours: 6 + i));
      
      // Check if we have a log for this specific hour
      final log = logs.firstWhere(
        (l) => l.logTime.hour == scheduledTime.hour,
        orElse: () => HydrationReminder(
          id: 'temp_$i',
          userId: '',
          logDate: today,
          logTime: scheduledTime,
          status: 'PENDING',
        ),
      );
      reminders.add(log);
    }
    
    state = HydrationState(isLoading: false, reminders: reminders);
  }

  Future<void> markAsDone(HydrationReminder reminder) async {
    final updated = HydrationReminder(
      id: reminder.id.startsWith('temp_') ? '' : reminder.id,
      userId: '',
      logDate: reminder.logDate,
      logTime: reminder.logTime,
      status: 'DONE',
    );
    await _repository.logHydration(updated);
    _loadTodayLogs();
  }

  Future<void> markAsSkipped(HydrationReminder reminder) async {
    final updated = HydrationReminder(
      id: reminder.id.startsWith('temp_') ? '' : reminder.id,
      userId: '',
      logDate: reminder.logDate,
      logTime: reminder.logTime,
      status: 'SKIPPED',
    );
    await _repository.logHydration(updated);
    _loadTodayLogs();
  }
}

extension on HydrationState {
  HydrationState copyWith({bool? isLoading, List<HydrationReminder>? reminders}) {
    return HydrationState(
      isLoading: isLoading ?? this.isLoading,
      reminders: reminders ?? this.reminders,
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
