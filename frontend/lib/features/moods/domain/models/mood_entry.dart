import 'package:equatable/equatable.dart';

class MoodEntry extends Equatable {
  final String id;
  final String userId;
  final DateTime logDate;
  final String mood; // happy, sad, neutral, stressed, excited, tired
  final String? note;

  const MoodEntry({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.mood,
    this.note,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      logDate: json['log_date'] != null ? DateTime.parse(json['log_date']) : DateTime.now(),
      mood: json['mood'] ?? 'neutral',
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_date': logDate.toIso8601String().split('T')[0],
      'mood': mood,
      'note': note,
    };
  }

  static String getEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return '😊';
      case 'sad': return '😢';
      case 'stressed': return '😫';
      case 'excited': return '🤩';
      case 'tired': return '😴';
      case 'neutral':
      default: return '😐';
    }
  }

  @override
  List<Object?> get props => [id, userId, logDate, mood, note];
}
