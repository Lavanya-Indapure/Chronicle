/// In-memory drafts for form sheets, keyed per form (e.g. `expense:new`,
/// `todo:edit:<id>`).
///
/// Drafts survive the sheet being dismissed (tap outside, swipe down, back)
/// and navigating around the app, for the lifetime of the app process.
/// Values are stored as-is (strings, numbers, bools, DateTimes, enums,
/// file paths), so nothing needs serialising.
abstract final class FormDraftStore {
  static final Map<String, Map<String, Object?>> _drafts = {};

  static Map<String, Object?>? read(String key) => _drafts[key];

  static void write(String key, Map<String, Object?> values) => _drafts[key] = Map.unmodifiable(values);

  static void clear(String key) => _drafts.remove(key);

  static bool has(String key) => _drafts.containsKey(key);

  /// Test helper: forget every draft.
  static void clearAll() => _drafts.clear();
}
