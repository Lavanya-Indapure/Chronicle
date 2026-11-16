import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/domain/models/todo_instance.dart';

/// Abstract interface for todo data operations.
abstract class TodoRepository {
  /// Fetch all active templates for the current user.
  Future<List<TodoTemplate>> getActiveTemplates();

  /// Fetch todo instances for a given date.
  Future<List<TodoInstance>> getInstancesForDate(DateTime date);

  /// Fetch todo instances between two dates (inclusive).
  Future<List<TodoInstance>> getInstancesBetweenDates(DateTime start, DateTime end);

  /// Create a new template + its first instance for today.
  Future<void> createTodo({
    required String title,
    String? description,
    required RecurrenceType recurrenceType,
  });

  /// Toggle completion of an instance.
  Future<void> toggleComplete(String instanceId, bool isCompleted);

  /// Update a template's title and recurrence.
  Future<void> updateTemplate({
    required String templateId,
    required String title,
    String? description,
    required RecurrenceType recurrenceType,
  });

  /// Soft-delete a template (cascades to instances).
  Future<void> deleteTemplate(String templateId);

  /// Create a new instance (for recurrence generation / carry forward).
  Future<void> createInstance(TodoInstance instance);

  /// Move an existing instance to [date] (pending weekly/monthly todos roll
  /// forward to today).
  Future<void> rescheduleInstance(String instanceId, DateTime date);

  /// Find incomplete one-time instances from before today (for carry forward).
  Future<List<TodoInstance>> getCarryForwardCandidates(DateTime today);
}
