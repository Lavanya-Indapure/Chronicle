import 'package:chronicle/core/errors/error_handler.dart';
import 'package:chronicle/core/services/logger_service.dart';
import 'package:chronicle/features/todos/data/datasources/todo_remote_datasource.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/domain/models/todo_instance.dart';
import 'package:chronicle/features/todos/domain/repositories/todo_repository.dart';

/// Concrete implementation of [TodoRepository].
class TodoRepositoryImpl implements TodoRepository {
  final TodoRemoteDatasource _datasource;

  TodoRepositoryImpl(this._datasource);

  @override
  Future<List<TodoTemplate>> getActiveTemplates() async {
    try {
      final data = await _datasource.getActiveTemplates();
      return data.map(TodoTemplate.fromJson).toList();
    } catch (e, st) {
      LoggerService.error('Failed to fetch templates', error: e, stackTrace: st, tag: 'Todo');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<TodoInstance>> getInstancesForDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;
      final data = await _datasource.getInstancesForDate(dateStr);
      return data.map(TodoInstance.fromJson).toList();
    } catch (e, st) {
      LoggerService.error('Failed to fetch instances', error: e, stackTrace: st, tag: 'Todo');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<TodoInstance>> getInstancesBetweenDates(DateTime start, DateTime end) async {
    try {
      final startStr = start.toIso8601String().split('T').first;
      final endStr = end.toIso8601String().split('T').first;
      final data = await _datasource.getInstancesBetweenDates(startStr, endStr);
      return data.map(TodoInstance.fromJson).toList();
    } catch (e, st) {
      LoggerService.error('Failed to fetch instances between dates', error: e, stackTrace: st, tag: 'Todo');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> createTodo({
    required String title,
    String? description,
    required RecurrenceType recurrenceType,
  }) async {
    try {
      final userId = _datasource.userId;

      // Create template
      final templateData = {
        'user_id': userId,
        'title': title,
        'description': description,
        'recurrence_type': recurrenceType.name,
        'is_active': true,
      };
      final template = await _datasource.insertTemplate(templateData);

      // Create today's instance
      final instanceData = {
        'template_id': template['id'],
        'user_id': userId,
        'title': title,
        'description': description,
        'scheduled_date': DateTime.now().toIso8601String().split('T').first,
      };
      await _datasource.insertInstance(instanceData);

      LoggerService.info('Created todo: $title ($recurrenceType)', tag: 'Todo');
    } catch (e, st) {
      LoggerService.error('Failed to create todo', error: e, stackTrace: st, tag: 'Todo');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> toggleComplete(String instanceId, bool isCompleted) async {
    try {
      await _datasource.updateInstanceCompletion(instanceId, isCompleted);
      LoggerService.info('Toggled instance $instanceId → $isCompleted', tag: 'Todo');
    } catch (e, st) {
      LoggerService.error('Failed to toggle', error: e, stackTrace: st, tag: 'Todo');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> updateTemplate({
    required String templateId,
    required String title,
    String? description,
    required RecurrenceType recurrenceType,
  }) async {
    try {
      // 1. Update template
      await _datasource.updateTemplate(templateId, {
        'title': title,
        'description': description,
        'recurrence_type': recurrenceType.name,
      });

      // 2. Update today's instance (so UI reflects change immediately)
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      await _datasource.updateInstancesByTemplate(
        templateId,
        todayStr,
        {
          'title': title,
          'description': description,
        },
      );

      LoggerService.info('Updated template $templateId and synced today instances', tag: 'Todo');
    } catch (e, st) {
      LoggerService.error('Failed to update template', error: e, stackTrace: st, tag: 'Todo');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    try {
      await _datasource.deleteInstancesByTemplate(templateId);
      await _datasource.softDeleteTemplate(templateId);
      LoggerService.info('Deleted template $templateId', tag: 'Todo');
    } catch (e, st) {
      LoggerService.error('Failed to delete template', error: e, stackTrace: st, tag: 'Todo');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> createInstance(TodoInstance instance) async {
    try {
      await _datasource.insertInstance(instance.toInsertJson());
    } catch (e, st) {
      LoggerService.error('Failed to create instance', error: e, stackTrace: st, tag: 'Todo');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> rescheduleInstance(String instanceId, DateTime date) async {
    try {
      await _datasource.rescheduleInstance(instanceId, date.toIso8601String().split('T').first);
    } catch (e, st) {
      LoggerService.error('Failed to reschedule instance', error: e, stackTrace: st, tag: 'Todo');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<TodoInstance>> getCarryForwardCandidates(DateTime today) async {
    try {
      final data = await _datasource.getCarryForwardCandidates(_datasource.userId, today);
      return data.map(TodoInstance.fromJson).toList();
    } catch (e, st) {
      LoggerService.error('Failed to get carry forward candidates', error: e, stackTrace: st, tag: 'Todo');
      throw ErrorHandler.handle(e);
    }
  }
}
