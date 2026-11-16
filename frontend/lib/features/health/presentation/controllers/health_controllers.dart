import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/core/errors/app_exception.dart';
import 'package:chronicle/features/health/data/datasources/health_remote_datasource.dart';
import 'package:chronicle/features/health/data/repositories/health_repository_impl.dart';
import 'package:chronicle/features/health/domain/health_stats.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';
import 'package:chronicle/features/health/domain/repositories/health_repository.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepositoryImpl(HealthRemoteDatasource(Supabase.instance.client));
});

DateTime _today() => HealthStats.day(DateTime.now());

// ── Settings ──

class HealthSettingsState extends Equatable {
  final bool isLoading;
  final HealthSettings settings;
  final String? errorMessage;

  const HealthSettingsState({this.isLoading = false, this.settings = const HealthSettings(), this.errorMessage});

  @override
  List<Object?> get props => [isLoading, settings, errorMessage];
}

class HealthSettingsController extends Notifier<HealthSettingsState> {
  late HealthRepository _repository;

  @override
  HealthSettingsState build() {
    _repository = ref.watch(healthRepositoryProvider);
    Future.microtask(load);
    return const HealthSettingsState(isLoading: true);
  }

  Future<void> load() async {
    try {
      state = HealthSettingsState(settings: await _repository.getSettings());
    } on AppException catch (e) {
      state = HealthSettingsState(settings: state.settings, errorMessage: e.message);
    }
  }

  /// Applies [next] immediately; reverts if saving fails.
  Future<bool> update(HealthSettings next) async {
    final previous = state.settings;
    state = HealthSettingsState(settings: next);
    try {
      await _repository.saveSettings(next);
      return true;
    } on AppException catch (e) {
      state = HealthSettingsState(settings: previous, errorMessage: e.message);
      return false;
    }
  }
}

final healthSettingsProvider =
    NotifierProvider<HealthSettingsController, HealthSettingsState>(HealthSettingsController.new);

// ── Hydration ──

class HydrationState extends Equatable {
  final bool isLoading;
  final List<HydrationReminder> slots;
  final String? errorMessage;

  const HydrationState({this.isLoading = false, this.slots = const [], this.errorMessage});

  int get doneCount => slots.where((s) => s.status == HydrationStatus.done).length;
  double get fraction => HealthStats.hydrationFraction(slots);

  /// Earliest pending slot whose time has come — what "Log a glass" ticks.
  /// Falls back to the next upcoming pending slot.
  HydrationReminder? get nextToLog {
    final now = DateTime.now();
    final pending = slots.where((s) => s.status == HydrationStatus.pending).toList();
    return pending.where((s) => !s.logTime.isAfter(now)).firstOrNull ?? pending.firstOrNull;
  }

  HydrationReminder? get nextUpcoming {
    final now = DateTime.now();
    return slots.where((s) => s.status == HydrationStatus.pending && s.logTime.isAfter(now)).firstOrNull;
  }

  HydrationState copyWith({bool? isLoading, List<HydrationReminder>? slots, String? errorMessage}) =>
      HydrationState(
        isLoading: isLoading ?? this.isLoading,
        slots: slots ?? this.slots,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [isLoading, slots, errorMessage];
}

class HydrationController extends Notifier<HydrationState> {
  late HealthRepository _repository;

  @override
  HydrationState build() {
    _repository = ref.watch(healthRepositoryProvider);
    // Rebuild slots whenever the schedule changes.
    ref.listen(healthSettingsProvider.select((s) => s.settings), (previous, next) => load());
    Future.microtask(load);
    return const HydrationState(isLoading: true);
  }

  Future<void> load() async {
    try {
      final logs = await _repository.getHydrationLogs(_today());
      final settings = ref.read(healthSettingsProvider).settings;
      state = HydrationState(slots: HealthStats.hydrationSlots(settings, logs, _today()));
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> markDone(HydrationReminder slot) => _set(slot, HydrationStatus.done);

  Future<void> markSkipped(HydrationReminder slot) => _set(slot, HydrationStatus.skipped);

  /// Back to pending (removes the stored log).
  Future<void> undo(HydrationReminder slot) => _set(slot, HydrationStatus.pending);

  Future<void> logGlass() async {
    final slot = state.nextToLog;
    if (slot != null) await markDone(slot);
  }

  /// Optimistic update; reverts on failure.
  Future<void> _set(HydrationReminder slot, HydrationStatus status) async {
    final previous = state.slots;
    _replace(slot, slot.withStatus(status));
    try {
      if (status == HydrationStatus.pending) {
        if (slot.isStored) await _repository.deleteHydration(slot.id);
        _replace(slot, slot.withStatus(status, id: ''));
      } else {
        _replace(slot, await _repository.saveHydration(slot.withStatus(status)));
      }
    } on AppException catch (e) {
      state = state.copyWith(slots: previous, errorMessage: e.message);
    }
  }

  void _replace(HydrationReminder old, HydrationReminder next) {
    state = state.copyWith(slots: [for (final s in state.slots) s.slotKey == old.slotKey ? next : s]);
  }
}

final hydrationControllerProvider = NotifierProvider<HydrationController, HydrationState>(HydrationController.new);

// ── Sleep ──

class SleepState extends Equatable {
  /// How far back the sleep screen loads.
  static const historyDays = 30;

  final bool isLoading;
  final SleepRecord? current;
  final List<SleepRecord> history;
  final String? errorMessage;

  const SleepState({this.isLoading = false, this.current, this.history = const [], this.errorMessage});

  bool get isSleeping => current != null;
  SleepRecord? get last => HealthStats.lastSleep(history);
  Duration? get weeklyAverage => HealthStats.averageSleep(history, DateTime.now());
  Map<DateTime, Duration> get lastSevenNights => HealthStats.sleepByNight(history, DateTime.now());

  @override
  List<Object?> get props => [isLoading, current, history, errorMessage];
}

class SleepController extends Notifier<SleepState> {
  late HealthRepository _repository;

  @override
  SleepState build() {
    _repository = ref.watch(healthRepositoryProvider);
    Future.microtask(load);
    return const SleepState(isLoading: true);
  }

  Future<void> load() async {
    try {
      final since = _today().subtract(const Duration(days: SleepState.historyDays));
      final results = await Future.wait([_repository.getSleepSince(since), _repository.getOpenSleep()]);
      final all = results[0] as List<SleepRecord>;
      state = SleepState(
        current: results[1] as SleepRecord?,
        history: all.where((r) => !r.isRecording).toList(),
      );
    } on AppException catch (e) {
      state = SleepState(current: state.current, history: state.history, errorMessage: e.message);
    }
  }

  Future<void> startSleep() => _run(() => _repository.startSleep(DateTime.now()));

  Future<void> wakeUp() async {
    final current = state.current;
    if (current == null) return;
    await _run(() => _repository.finishSleep(current.id, current.startTime, DateTime.now()));
  }

  /// Discards a session started by mistake.
  Future<void> cancelSleep() async {
    final current = state.current;
    if (current == null) return;
    await _run(() => _repository.deleteSleep(current.id));
  }

  /// Manual entry for a night that wasn't tracked live.
  Future<bool> addSleep(DateTime start, DateTime end) => _run(() => _repository.addSleep(start, end));

  Future<bool> deleteSleep(String id) => _run(() => _repository.deleteSleep(id));

  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      await load();
      return true;
    } on AppException catch (e) {
      state = SleepState(current: state.current, history: state.history, errorMessage: e.message);
      return false;
    }
  }
}

final sleepControllerProvider = NotifierProvider<SleepController, SleepState>(SleepController.new);

// ── Activity ──

class ActivityState extends Equatable {
  /// How far back the activity screen loads (enough for streaks & history).
  static const historyDays = 60;

  final bool isLoading;
  final List<ActivityLog> logs;
  final String? errorMessage;

  const ActivityState({this.isLoading = false, this.logs = const [], this.errorMessage});

  ActivityLog get today {
    final day = _today();
    return logs.where((l) => HealthStats.day(l.logDate) == day).firstOrNull ?? ActivityLog.empty(day);
  }

  int get exerciseStreak => HealthStats.streak(logs, DateTime.now(), (l) => l.exerciseDone);
  int get meditationStreak => HealthStats.streak(logs, DateTime.now(), (l) => l.meditationDone);

  ActivityLog? logFor(DateTime day) => logs.where((l) => HealthStats.day(l.logDate) == day).firstOrNull;

  @override
  List<Object?> get props => [isLoading, logs, errorMessage];
}

class ActivityController extends Notifier<ActivityState> {
  late HealthRepository _repository;

  @override
  ActivityState build() {
    _repository = ref.watch(healthRepositoryProvider);
    Future.microtask(load);
    return const ActivityState(isLoading: true);
  }

  Future<void> load() async {
    try {
      final since = _today().subtract(const Duration(days: ActivityState.historyDays));
      state = ActivityState(logs: await _repository.getActivitySince(since));
    } on AppException catch (e) {
      state = ActivityState(logs: state.logs, errorMessage: e.message);
    }
  }

  Future<void> toggleExercise() => _save(state.today.copyWith(exerciseDone: !state.today.exerciseDone));

  Future<void> toggleMeditation() => _save(state.today.copyWith(meditationDone: !state.today.meditationDone));

  Future<bool> saveNotes(String notes) => _save(state.today.copyWith(notes: notes.trim()));

  /// Optimistic update of today's row; reverts on failure.
  Future<bool> _save(ActivityLog next) async {
    final previous = state.logs;
    state = ActivityState(logs: _withToday(previous, next));
    try {
      final saved = await _repository.saveActivity(next);
      state = ActivityState(logs: _withToday(state.logs, saved));
      return true;
    } on AppException catch (e) {
      state = ActivityState(logs: previous, errorMessage: e.message);
      return false;
    }
  }

  List<ActivityLog> _withToday(List<ActivityLog> logs, ActivityLog today) {
    final day = HealthStats.day(today.logDate);
    return [today, ...logs.where((l) => HealthStats.day(l.logDate) != day)];
  }
}

final activityControllerProvider = NotifierProvider<ActivityController, ActivityState>(ActivityController.new);
