import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:chronicle/core/services/form_draft_store.dart';

/// Keeps a form sheet's unsaved input as a draft when the sheet is dismissed
/// without saving, and restores it the next time the same form opens.
///
/// How to use in a sheet's State:
/// 1. `with DraftFormMixin<MySheet>` and implement [draftKey], [captureDraft]
///    and [restoreDraft].
/// 2. Call [initDraft] at the end of `initState` (after controllers and
///    initial values are set up).
/// 3. Call [markSubmitted] right after a successful save.
/// 4. Show `if (draftRestored) DraftRestoredBanner(onDiscard: discardDraft)`
///    near the sheet title.
///
/// [restoreDraft] must treat missing keys as "use the form's starting value",
/// so `restoreDraft(const {})` resets the form (used by [discardDraft]).
mixin DraftFormMixin<T extends StatefulWidget> on State<T> {
  /// Unique per form, and per item for edit forms (e.g. `todo:edit:<id>`).
  String get draftKey;

  /// Current field values. Use simple values (String, num, bool, DateTime,
  /// enums, file paths).
  Map<String, Object?> captureDraft();

  /// Applies [draft] to the fields; missing keys reset to starting values.
  void restoreDraft(Map<String, Object?> draft);

  Map<String, Object?> _baseline = const {};
  bool _submitted = false;
  bool _draftRestored = false;

  /// Whether this sheet opened with a restored draft (show the banner).
  bool get draftRestored => _draftRestored;

  @protected
  void initDraft() {
    _baseline = captureDraft();
    final draft = FormDraftStore.read(draftKey);
    if (draft != null) {
      restoreDraft(draft);
      _draftRestored = true;
    }
  }

  /// Call after a successful save so the draft isn't kept.
  @protected
  void markSubmitted() {
    _submitted = true;
    FormDraftStore.clear(draftKey);
  }

  /// Throws the draft away and resets the form to its starting values.
  void discardDraft() {
    FormDraftStore.clear(draftKey);
    setState(() {
      restoreDraft(const {});
      _draftRestored = false;
    });
  }

  @override
  void deactivate() {
    // deactivate (not dispose) so controllers are still alive here.
    if (!_submitted) {
      final values = captureDraft();
      if (mapEquals(values, _baseline)) {
        FormDraftStore.clear(draftKey); // nothing changed → no draft
      } else {
        FormDraftStore.write(draftKey, values);
      }
    }
    super.deactivate();
  }
}
