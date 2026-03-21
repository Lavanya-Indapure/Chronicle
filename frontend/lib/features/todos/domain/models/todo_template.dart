/// Recurrence type for todo templates.
enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly;

  String get label {
    switch (this) {
      case RecurrenceType.none:
        return 'One-time';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
    }
  }

  static RecurrenceType fromString(String value) {
    return RecurrenceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RecurrenceType.none,
    );
  }
}

/// Blueprint for a recurring or one-time todo.
class TodoTemplate {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? categoryId;
  final String priority;
  final RecurrenceType recurrenceType;
  final List<int>? recurrenceDays;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const TodoTemplate({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.categoryId,
    this.priority = 'medium',
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceDays,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory TodoTemplate.fromJson(Map<String, dynamic> json) {
    return TodoTemplate(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      recurrenceType: RecurrenceType.fromString(json['recurrence_type'] as String? ?? 'none'),
      recurrenceDays: (json['recurrence_days'] as List<dynamic>?)?.cast<int>(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'title': title,
        if (description != null) 'description': description,
        if (categoryId != null) 'category_id': categoryId,
        'priority': priority,
        'recurrence_type': recurrenceType.name,
        if (recurrenceDays != null) 'recurrence_days': recurrenceDays,
        'is_active': isActive,
      };

  TodoTemplate copyWith({
    String? title,
    String? description,
    RecurrenceType? recurrenceType,
    List<int>? recurrenceDays,
  }) =>
      TodoTemplate(
        id: id,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        categoryId: categoryId,
        priority: priority,
        recurrenceType: recurrenceType ?? this.recurrenceType,
        recurrenceDays: recurrenceDays ?? this.recurrenceDays,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}
