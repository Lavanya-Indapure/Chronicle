import 'dart:convert';

/// Tag helpers shared by every taggable module (thoughts, life lessons,
/// books, learnings, movies). Tags are stored as a Postgres `text[]`.
abstract final class TagUtils {
  /// Splits "growth, Patience ,growth" into ["growth", "Patience"]:
  /// trimmed, blanks dropped, a leading "#" removed, duplicates
  /// (case-insensitive) removed — first spelling wins.
  static List<String> parse(String input) {
    final seen = <String>{};
    return [
      for (final raw in input.split(','))
        if (_clean(raw).isNotEmpty && seen.add(_clean(raw).toLowerCase())) _clean(raw),
    ];
  }

  static String _clean(String raw) {
    final t = raw.trim();
    return t.startsWith('#') ? t.substring(1).trim() : t;
  }

  /// Text-field form of [tags]: "growth, patience".
  static String format(List<String> tags) => tags.join(', ');

  /// Reads a `tags` value from a database row. Accepts the `text[]` form
  /// (a JSON list) and the legacy comma-separated `text` form — including
  /// a JSON-array string, which is what a list written to a `text` column
  /// looks like — so rows read correctly before and after the migration.
  static List<String> fromJson(Object? value) {
    if (value == null) return const [];
    if (value is List) return parse(value.map((e) => '$e').join(','));
    final text = '$value'.trim();
    if (text.startsWith('[')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) return fromJson(decoded);
      } on FormatException {
        // Not JSON after all — fall through to comma parsing.
      }
    }
    return parse(text);
  }

  /// Whether [tags] contains [tag], ignoring case. A null [tag] matches all.
  static bool has(List<String> tags, String? tag) {
    if (tag == null) return true;
    final lower = tag.toLowerCase();
    return tags.any((t) => t.toLowerCase() == lower);
  }

  /// Every tag in use across [lists], de-duplicated case-insensitively and
  /// sorted alphabetically (first spelling wins).
  static List<String> collect(Iterable<List<String>> lists) {
    final byLower = <String, String>{};
    for (final list in lists) {
      for (final t in list) {
        byLower.putIfAbsent(t.toLowerCase(), () => t);
      }
    }
    return byLower.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Value to write for a `tags` column, or null to leave the column out of
  /// the write. Untagged rows that stay untagged omit it, so saving keeps
  /// working on a database where the `tags` column hasn't been added yet.
  static List<String>? forWrite(List<String> next, {List<String> previous = const []}) =>
      next.isEmpty && previous.isEmpty ? null : next;

  /// Whether any tag contains [query] (already lower-cased).
  static bool anyContains(List<String> tags, String query) => tags.any((t) => t.toLowerCase().contains(query));
}
