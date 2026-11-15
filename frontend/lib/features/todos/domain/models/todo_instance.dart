/// A concrete instance of a todo for a specific date.
class TodoInstance {
  final String id;
  final String? templateId;
  final String userId;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool isCarriedForward;
  final DateTime? carriedFromDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoInstance({
    required this.id,
    this.templateId,
    required this.userId,
    required this.title,
    this.description,
    required this.scheduledDate,
    this.isCompleted = false,
    this.completedAt,
    this.isCarriedForward = false,
    this.carriedFromDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TodoInstance.fromJson(Map<String, dynamic> json) {
    return TodoInstance(
      id: json['id'] as String,
      templateId: json['template_id'] as String?,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      isCarriedForward: json['is_carried_forward'] as bool? ?? false,
      carriedFromDate: json['carried_from_date'] != null ? DateTime.parse(json['carried_from_date'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Copy with a new completion state (used for optimistic UI updates).
  TodoInstance withCompleted(bool completed) => TodoInstance(
        id: id,
        templateId: templateId,
        userId: userId,
        title: title,
        description: description,
        scheduledDate: scheduledDate,
        isCompleted: completed,
        completedAt: completed ? DateTime.now() : null,
        isCarriedForward: isCarriedForward,
        carriedFromDate: carriedFromDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toInsertJson() => {
        if (templateId != null) 'template_id': templateId,
        'user_id': userId,
        'title': title,
        if (description != null) 'description': description,
        'scheduled_date': scheduledDate.toIso8601String().split('T').first,
        'is_completed': isCompleted,
        'is_carried_forward': isCarriedForward,
        if (carriedFromDate != null) 'carried_from_date': carriedFromDate!.toIso8601String().split('T').first,
      };
}
