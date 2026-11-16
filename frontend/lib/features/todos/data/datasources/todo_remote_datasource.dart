import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote datasource — all Supabase calls for todo operations.
class TodoRemoteDatasource {
  final SupabaseClient client;

  TodoRemoteDatasource(this.client);

  String get userId => client.auth.currentUser!.id;

  /// Fetch all active (non-deleted) templates for the current user.
  Future<List<Map<String, dynamic>>> getActiveTemplates() async {
    final currentUserId = userId;
    final response = await client
        .from('todo_templates')
        .select('*')
        .eq('user_id', currentUserId)
        .filter('deleted_at', 'is', null)
        .eq('is_active', true)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch instances for a given date.
  Future<List<Map<String, dynamic>>> getInstancesForDate(String dateStr) async {
    final currentUserId = userId;
    // Note: We're using print here for immediate visibility in debug console if available
    // but LoggerService is preferred.
    final response = await client
        .from('todo_instances')
        .select('*')
        .eq('user_id', currentUserId)
        .eq('scheduled_date', dateStr)
        .order('is_completed', ascending: true)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch instances between two dates (inclusive).
  Future<List<Map<String, dynamic>>> getInstancesBetweenDates(String startDateStr, String endDateStr) async {
    final currentUserId = userId;
    final response = await client
        .from('todo_instances')
        .select('*')
        .eq('user_id', currentUserId)
        .gte('scheduled_date', startDateStr)
        .lte('scheduled_date', endDateStr)
        .order('scheduled_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Insert a new template.
  Future<Map<String, dynamic>> insertTemplate(Map<String, dynamic> data) async {
    final response = await client
        .from('todo_templates')
        .insert(data)
        .select()
        .single();
    return response;
  }

  /// Insert a new instance.
  Future<Map<String, dynamic>> insertInstance(Map<String, dynamic> data) async {
    final response = await client
        .from('todo_instances')
        .insert(data)
        .select()
        .single();
    return response;
  }

  /// Update instance completion status.
  Future<void> updateInstanceCompletion(String id, bool isCompleted) async {
    await client.from('todo_instances').update({
      'is_completed': isCompleted,
      'completed_at': isCompleted ? DateTime.now().toUtc().toIso8601String() : null,
    }).eq('id', id);
  }

  /// Update template.
  Future<void> updateTemplate(String id, Map<String, dynamic> data) async {
    await client.from('todo_templates').update(data).eq('id', id);
  }

  /// Update all instances of a template for a specific date (e.g. today).
  Future<void> updateInstancesByTemplate(String templateId, String dateStr, Map<String, dynamic> data) async {
    await client
        .from('todo_instances')
        .update(data)
        .eq('template_id', templateId)
        .eq('scheduled_date', dateStr);
  }

  /// Soft-delete a template.
  Future<void> softDeleteTemplate(String id) async {
    await client.from('todo_templates').update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
      'is_active': false,
    }).eq('id', id);
  }

  /// Delete all instances of a template.
  Future<void> deleteInstancesByTemplate(String templateId) async {
    await client.from('todo_instances').delete().eq('template_id', templateId);
  }

  /// Find one-time todos from before [date] that are still unfinished, one
  /// row per todo (its most recent instance).
  ///
  /// Each carry-forward creates a new instance, so a one-time todo becomes a
  /// chain of instances across days. The todo is finished as soon as ANY
  /// instance in its chain is completed — the older, never-ticked copies must
  /// not bring it back.
  Future<List<Map<String, dynamic>>> getCarryForwardCandidates(String userId, DateTime date) async {
    final todayStr = date.toIso8601String().split('T')[0];

    // Incomplete instances from before today (originals and carried copies),
    // joined with their template to check recurrence_type.
    final response = await client
        .from('todo_instances')
        .select('*, todo_templates!left(recurrence_type, deleted_at, is_active)')
        .eq('user_id', userId)
        .eq('is_completed', false)
        .lt('scheduled_date', todayStr);

    final oneTime = List<Map<String, dynamic>>.from(response).where((i) {
      if (i['template_id'] == null) return true; // manual one-time instance
      final template = i['todo_templates'] as Map<String, dynamic>?;
      if (template == null) return false;
      if (template['deleted_at'] != null || template['is_active'] == false) return false;
      return template['recurrence_type'] == 'none';
    }).toList();
    if (oneTime.isEmpty) return [];

    // Templates that already have a completed instance (on any date) are done.
    final templateIds = oneTime
        .map((i) => i['template_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final doneTemplateIds = <String>{};
    if (templateIds.isNotEmpty) {
      final completed = await client
          .from('todo_instances')
          .select('template_id')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .inFilter('template_id', templateIds);
      for (final row in List<Map<String, dynamic>>.from(completed)) {
        doneTemplateIds.add(row['template_id'] as String);
      }
    }

    // Keep only the latest instance of each unfinished todo.
    final latest = <String, Map<String, dynamic>>{};
    for (final i in oneTime) {
      final templateId = i['template_id'] as String?;
      if (templateId != null && doneTemplateIds.contains(templateId)) continue;
      final key = templateId ?? 'title:${i['title']}';
      final current = latest[key];
      if (current == null ||
          (i['scheduled_date'] as String).compareTo(current['scheduled_date'] as String) > 0) {
        latest[key] = i;
      }
    }
    return latest.values.toList();
  }

  /// Check if an instance already exists for a template on a given date.
  Future<bool> instanceExistsForDate(String templateId, String dateStr) async {
    final response = await client
        .from('todo_instances')
        .select('id')
        .eq('template_id', templateId)
        .eq('scheduled_date', dateStr)
        .limit(1);
    return (response as List).isNotEmpty;
  }
}
