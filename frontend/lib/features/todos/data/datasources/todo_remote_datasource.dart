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

  /// Find incomplete one-time instances from before a given date.
  Future<List<Map<String, dynamic>>> getCarryForwardCandidates(String userId, DateTime date) async {
    final todayStr = date.toIso8601String().split('T')[0];
    
    // Fetch all incomplete, non-carried instances from before today.
    // We join todo_templates to check the recurrence_type in Dart.
    final response = await client
        .from('todo_instances')
        .select('*, todo_templates!left(recurrence_type)')
        .eq('user_id', userId)
        .eq('is_completed', false)
        .eq('is_carried_forward', false)
        .lt('scheduled_date', todayStr);
        
    final List<Map<String, dynamic>> instances = List<Map<String, dynamic>>.from(response);

    // Filter in Dart: manual one-time (template_id is null) OR 'none' recurrence template
    return instances.where((i) {
      final templateData = i['todo_templates'] as Map<String, dynamic>?;
      final recurrenceType = templateData?['recurrence_type'] as String?;
      
      return i['template_id'] == null || recurrenceType == 'none';
    }).toList();
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
