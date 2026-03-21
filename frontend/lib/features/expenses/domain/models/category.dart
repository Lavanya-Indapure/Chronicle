import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String type; // 'todo' or 'expense'
  final String? icon;
  final String? color;
  final String? userId; // Null for system categories

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.userId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'user_id': userId,
    };
  }

  @override
  List<Object?> get props => [id, name, type, icon, color, userId];
}
