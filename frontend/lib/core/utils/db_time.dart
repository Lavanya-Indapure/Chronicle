import 'package:flutter/material.dart';

/// Wall-clock date/time encoding for Supabase columns.
///
/// Values are written as local wall-clock time without an offset and read
/// back by ignoring any offset the database adds. This round-trips the same
/// clock time whether the column is `timestamp` or `timestamptz`, so a
/// reminder logged "at 07:30" always reads back as 07:30.
abstract final class DbTime {
  /// `2026-11-16T07:30:00` (local wall clock, no offset).
  static String encode(DateTime local) {
    final d = local.isUtc ? local.toLocal() : local;
    return '${date(d)}T${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';
  }

  /// Parses a value written by [encode] (or any ISO string), keeping the
  /// clock fields as-is and dropping a trailing `Z` / `+hh:mm` offset.
  static DateTime decode(String value) {
    final match = RegExp(r'^(\d{4}-\d{2}-\d{2})[T ](\d{2}:\d{2}(:\d{2})?)').firstMatch(value);
    if (match == null) return DateTime.parse(value).toLocal();
    return DateTime.parse('${match.group(1)}T${match.group(2)}');
  }

  /// `2026-11-16` for a `date` column.
  static String date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  /// `07:30` for a `time`/text column.
  static String time(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

  /// Parses `07:30` or `07:30:00`; returns [fallback] when unparseable.
  static TimeOfDay parseTime(String? value, TimeOfDay fallback) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value ?? '');
    if (match == null) return fallback;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    if (h > 23 || m > 59) return fallback;
    return TimeOfDay(hour: h, minute: m);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
