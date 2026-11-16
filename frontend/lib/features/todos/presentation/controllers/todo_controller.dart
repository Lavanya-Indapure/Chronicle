import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/todos/data/datasources/todo_remote_datasource.dart';
import 'package:chronicle/features/todos/data/repositories/todo_repository_impl.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/domain/models/todo_instance.dart';
import 'package:chronicle/features/todos/domain/repositories/todo_repository.dart';
import 'package:chronicle/features/todos/domain/recurrence_rules.dart';
import 'package:chronicle/core/errors/app_exception.dart';
import 'package:chronicle/core/services/logger_service.dart';

// ── State ──
class TodoState {
  final bool isLoading;
  final String? errorMessage;
  final Map<RecurrenceType, List<TodoInstance>> groupedTodos;
  final List<TodoTemplate> templates;

  const TodoState({
    this.isLoading = false,
    this.errorMessage,
    this.groupedTodos = const {},
    this.templates = const [],
  });

  TodoState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<RecurrenceType, List<TodoInstance>>? groupedTodos,
    List<TodoTemplate>? templates,
  }) =>
      TodoState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        groupedTodos: groupedTodos ?? this.groupedTodos,
        templates: templates ?? this.templates,
      );

  List<TodoInstance> get allTodos =>
      groupedTodos.values.expand((list) => list).toList();

  int get completedCount => allTodos.where((t) => t.isCompleted).length;
  int get totalCount => allTodos.length;
}

// ── DI ──
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final client = Supabase.instance.client;
  final datasource = TodoRemoteDatasource(client);
  return TodoRepositoryImpl(datasource);
});

final todoControllerProvider =
    NotifierProvider<TodoController, TodoState>(TodoController.new);

// ── Controller ──
class TodoController extends Notifier<TodoState> {
  late final TodoRepository _repository;

  @override
  TodoState build() {
    _repository = ref.watch(todoRepositoryProvider);
    // Auto-load on creation
    Future.microtask(() => loadTodayTodos());
    return const TodoState(isLoading: true);
  }

  /// Load today's todos: generate instances from templates + carry forward.
  ///
  /// With [silent], the current list stays on screen while refreshing
  /// (used after edits so the list doesn't flash to a spinner).
  Future<void> loadTodayTodos({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final today = DateTime.now();
      // 0. Check session
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        LoggerService.error('Current user is null in loadTodayTodos', tag: 'Todo');
        state = state.copyWith(isLoading: false, errorMessage: 'Session expired. Please log in again.');
        return;
      }
      final todayStr = today.toIso8601String().split('T').first;

      // 1. Get active templates
      final templates = await _repository.getActiveTemplates();
      LoggerService.info('Fetched ${templates.length} templates', tag: 'Todo');

      // 2. Get existing instances for today
      var instances = await _repository.getInstancesForDate(today);
      LoggerService.info('Fetched ${instances.length} instances for today before generation', tag: 'Todo');

      // 3. Make sure every recurring template due in its current period is on
      //    today's list (see RecurrenceRules). Weekly/monthly need the whole
      //    period's instances — fetched in one query for all templates.
      final needsPeriod = templates.any((t) => RecurrenceRules.spansPeriod(t.recurrenceType));
      final periodInstances = needsPeriod
          ? await _repository.getInstancesBetweenDates(RecurrenceRules.earliestPeriodStart(today), today)
          : instances;
      final byTemplate = <String, List<TodoInstance>>{};
      for (final i in [...instances, ...periodInstances]) {
        if (i.templateId != null) byTemplate.putIfAbsent(i.templateId!, () => []).add(i);
      }

      for (final template in templates) {
        final plan = RecurrenceRules.planToday(
          type: template.recurrenceType,
          today: today,
          instances: byTemplate[template.id] ?? const [],
        );
        switch (plan.kind) {
          case TodayPlanKind.none:
            break;
          case TodayPlanKind.move:
            await _repository.rescheduleInstance(plan.instanceId!, today);
          case TodayPlanKind.create:
            await _repository.createInstance(TodoInstance(
              id: '', // will be set by DB
              templateId: template.id,
              userId: template.userId,
              title: template.title,
              description: template.description,
              scheduledDate: today,
              createdAt: today,
              updatedAt: today,
            ));
        }
      }

      // 4. Carry forward incomplete one-time tasks
      final candidates = await _repository.getCarryForwardCandidates(today);
      for (final old in candidates) {
        // Skip if this todo already has an instance today (carried earlier
        // today, or created today).
        final alreadyToday = instances.any((i) =>
            (old.templateId != null
                ? i.templateId == old.templateId
                : i.templateId == null && i.title == old.title) &&
            i.scheduledDate.toIso8601String().split('T').first == todayStr);
        if (alreadyToday) continue;

        final carried = TodoInstance(
          id: '',
          templateId: old.templateId,
          userId: old.userId,
          title: old.title,
          description: old.description,
          scheduledDate: today,
          isCarriedForward: true,
          // Keep pointing at the day the todo was first scheduled.
          carriedFromDate: old.carriedFromDate ?? old.scheduledDate,
          createdAt: today,
          updatedAt: today,
        );
        await _repository.createInstance(carried);
      }

      // 5. Re-fetch and group
      instances = await _repository.getInstancesForDate(today);
      LoggerService.info('Final instance count for grouping: ${instances.length}', tag: 'Todo');
      
      final grouped = _groupInstances(instances, templates);
      LoggerService.info('Grouped into ${grouped.length} recurrence categories', tag: 'Todo');

      state = state.copyWith(
        isLoading: false,
        groupedTodos: grouped,
        templates: templates,
      );
    } on AppException catch (e) {
      LoggerService.error('AppException loading todos: ${e.message}', error: e, tag: 'Todo');
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e, st) {
      LoggerService.error('Unexpected error loading todos', error: e, stackTrace: st, tag: 'Todo');
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred');
    }
  }

  /// Add a new todo.
  Future<bool> addTodo({
    required String title,
    String? description,
    required RecurrenceType recurrenceType,
  }) async {
    try {
      await _repository.createTodo(
        title: title,
        description: description,
        recurrenceType: recurrenceType,
      );
      await loadTodayTodos();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  /// Toggle completed state. Updates the UI immediately, then persists;
  /// reverts if the save fails.
  Future<void> toggleComplete(String instanceId, bool isCompleted) async {
    final previous = state.groupedTodos;
    state = state.copyWith(
      groupedTodos: _mapInstances(previous, (i) => i.id == instanceId ? i.withCompleted(isCompleted) : i),
    );
    try {
      await _repository.toggleComplete(instanceId, isCompleted);
    } on AppException catch (e) {
      state = state.copyWith(groupedTodos: previous, errorMessage: e.message);
    }
  }

  /// Applies [transform] to every instance; drops instances it maps to null
  /// and groups that end up empty.
  Map<RecurrenceType, List<TodoInstance>> _mapInstances(
    Map<RecurrenceType, List<TodoInstance>> grouped,
    TodoInstance? Function(TodoInstance) transform,
  ) {
    final result = <RecurrenceType, List<TodoInstance>>{};
    for (final entry in grouped.entries) {
      final items = entry.value.map(transform).whereType<TodoInstance>().toList();
      if (items.isNotEmpty) result[entry.key] = items;
    }
    return result;
  }

  /// Edit a template.
  Future<bool> editTodo({
    required String templateId,
    required String title,
    String? description,
    required RecurrenceType recurrenceType,
  }) async {
    try {
      await _repository.updateTemplate(
        templateId: templateId,
        title: title,
        description: description,
        recurrenceType: recurrenceType,
      );
      await loadTodayTodos(silent: true);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  /// Delete a template. Its instances leave the list immediately (a swiped
  /// row must not stay in the tree); restored if the delete fails.
  Future<void> deleteTodo(String templateId) async {
    final previous = state.groupedTodos;
    state = state.copyWith(
      groupedTodos: _mapInstances(previous, (i) => i.templateId == templateId ? null : i),
    );
    try {
      await _repository.deleteTemplate(templateId);
      await loadTodayTodos(silent: true);
    } on AppException catch (e) {
      state = state.copyWith(groupedTodos: previous, errorMessage: e.message);
    }
  }

  /// Group instances by their template's recurrence type.
  Map<RecurrenceType, List<TodoInstance>> _groupInstances(
    List<TodoInstance> instances,
    List<TodoTemplate> templates,
  ) {
    final templateMap = {for (final t in templates) t.id: t};
    final grouped = <RecurrenceType, List<TodoInstance>>{};

    // Order: daily → weekly → monthly → none (one-time)
    for (final type in RecurrenceType.values.reversed) {
      grouped[type] = [];
    }

    for (final instance in instances) {
      final template = instance.templateId != null
          ? templateMap[instance.templateId]
          : null;
      final type = template?.recurrenceType ?? RecurrenceType.none;
      grouped[type]!.add(instance);
    }

    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }
}
