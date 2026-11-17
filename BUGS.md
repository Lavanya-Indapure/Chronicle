# Chronicle — Bug Tracker

Bugs found in the full-app audit of 2026-11-16, plus anything found since.
Keep this file up to date: when a bug is fixed, tick its box, set **Status**, and add a one-line
note on the fix (and the test that covers it, if any). Add new bugs at the end of the right
section with the next free ID. Never reuse an ID.

**Status key:** `Open` · `Fixed` · `Partly fixed` · `Needs manual step` · `Won't fix`
**(unverified)** means the bug is plausible from the code but depends on timing or on database
tables that aren't in `supabase/migrations/`; confirm before fixing.

**Summary (last updated 2026-11-17):** 54 bugs — 5 High, 18 Medium, 31 Low. Fixed: all 5 High (H03 still needs the Supabase step) + 1 Low (L20).

---

## High

- [x] **H01 — Places, Moods, Learnings and First Times open empty even when the user has entries.** · Status: **Fixed** (2026-11-17)
  - Where: [place_controller.dart](frontend/lib/features/places/presentation/controllers/place_controller.dart), [mood_controller.dart](frontend/lib/features/moods/presentation/controllers/mood_controller.dart), [learning_controller.dart](frontend/lib/features/learnings/presentation/controllers/learning_controller.dart), [first_time_controller.dart](frontend/lib/features/first_times/presentation/controllers/first_time_controller.dart)
  - Cause: `build()` called the async loader directly; its first line reads `state` before it exists, which Riverpod 3 reports as an error, so the fetch never ran.
  - Fix: start the first load with `Future.microtask(...)` (same as the Books controller). Test: [controller_initial_load_test.dart](frontend/test/controller_initial_load_test.dart) (fails on the old code). First Times isn't covered by the test because its controller builds its Supabase client directly.

- [x] **H02 — Signing out leaves the previous user's data on screen.** · Status: **Fixed** (2026-11-17)
  - Scenario: A signs out, B signs in on the same device → B sees A's dashboard, "Hello A", todos, books, photos (via cached signed URLs), profile, A's unsaved form drafts, and A's water/dues notifications keep firing.
  - Fix: new [user_session_scope.dart](frontend/lib/core/widgets/user_session_scope.dart) wraps the app in [main.dart](frontend/lib/main.dart). When the signed-in user id changes it replaces the whole `ProviderScope` (all providers rebuilt), clears `FormDraftStore`, and on sign-out calls `NotificationService.cancelAll()`. `AuthController.signOut` now checks `ref.mounted`. Test: [user_session_scope_test.dart](frontend/test/user_session_scope_test.dart).
  - Side effect: the theme choice also resets on sign-out (it already reset on every restart; see L27).

- [x] **H03 — Password reset can't be completed.** · Status: **Fixed in code — Needs manual step**
  - Cause: the reset email had no `redirectTo`; no deep link was registered on Android/iOS; nothing reacted to the `passwordRecovery` auth event or ever opened `/reset-password`.
  - Fix: `redirectTo: com.lavanyaindapure.chronicle://reset-password` ([app_constants.dart](frontend/lib/core/constants/app_constants.dart), [auth_remote_datasource.dart](frontend/lib/features/auth/data/datasources/auth_remote_datasource.dart)); intent filter in [AndroidManifest.xml](frontend/android/app/src/main/AndroidManifest.xml) and `CFBundleURLTypes` in [Info.plist](frontend/ios/Runner/Info.plist); [app_router.dart](frontend/lib/core/router/app_router.dart) forces `/reset-password` while a recovery session is active, until `AppRouter.finishPasswordRecovery()` is called after the new password is saved.
  - **Manual step:** in the Supabase dashboard → Authentication → URL Configuration → Redirect URLs, add `com.lavanyaindapure.chronicle://reset-password`. Until then Supabase ignores the redirect.
  - Not covered: macOS/Windows/Linux deep links. On web the link goes to the Site URL, which must be the web app.
  - Needs a real-device check (email link → app → new password → dashboard).

- [x] **H04 — Expense and transaction date filters include the day after the end date.** · Status: **Fixed** (2026-11-17)
  - Where: `filteredExpenses` / `filteredTransactions` in [expense_controller.dart](frontend/lib/features/expenses/presentation/controllers/expense_controller.dart)
  - Scenario: `isAfter(endDate + 1 day)` let an item dated exactly endDate+1 through. Viewing October's history also listed 1 November.
  - Fix: new top-level `isWithinDays(date, start, end)` compares calendar days, both ends inclusive. Test: [expense_date_filters_test.dart](frontend/test/expense_date_filters_test.dart) (October tests fail on the old code).

- [x] **H05 — Expense date-range picker crashes when the current month is filtered.** · Status: **Fixed** (2026-11-17)
  - Where: [expense_filter_sheet.dart](frontend/lib/features/expenses/presentation/widgets/expense_filter_sheet.dart), and the same pattern in [transaction_filter_sheet.dart](frontend/lib/features/expenses/presentation/widgets/transaction_filter_sheet.dart)
  - Scenario: `lastDate: DateTime.now()` but `initialDateRange` ended 30 Nov → Flutter assertion (red screen in debug). A filter starting before 2020 tripped the `firstDate` assert (both sheets).
  - Fix: new [date_ranges.dart](frontend/lib/core/utils/date_ranges.dart) `pickerBounds(...)` widens firstDate/lastDate just enough to contain the active filter; both sheets use it. Test: picker group in [expense_date_filters_test.dart](frontend/test/expense_date_filters_test.dart) (fails on the old code with both assertions).

## Medium

- [ ] **M01 — Dashboard "This month" spend per day is understated.** · Status: Open
  - Where: [dashboard_controller.dart:107](frontend/lib/features/dashboard/presentation/controllers/dashboard_controller.dart#L107), range at [:222](frontend/lib/features/dashboard/presentation/controllers/dashboard_controller.dart#L222)
  - Divides by every day of the month, not days elapsed: on 16 Nov, ₹16,000 shows as ₹533/day instead of ~₹1,000.

- [ ] **M02 — Switching dashboard tabs quickly can show the wrong numbers.** · Status: Open
  - Where: `_fetchData` in [dashboard_controller.dart](frontend/lib/features/dashboard/presentation/controllers/dashboard_controller.dart)
  - No request token: tap Week then Today; if Week's fetch finishes last, Today shows the week's totals.

- [ ] **M03 — Dashboard doesn't refresh after changes made elsewhere.** · Status: Open
  - Ticking todos on the Todos tab or logging water doesn't update counts, streak, heatmap or hydration % until pull-to-refresh. Refresh is only called from quick add, expenses screens and Up Next.

- [ ] **M04 — Screens don't roll over to the new day after midnight.** · Status: Open
  - Todos ([todo_controller.dart](frontend/lib/features/todos/presentation/controllers/todo_controller.dart)), dashboard "Today", and Hydration ([health_controllers.dart:115](frontend/lib/features/health/presentation/controllers/health_controllers.dart#L115)) only load once. Worst case: "Log a glass" next morning records it against yesterday's slot.

- [ ] **M05 — Daily and carried-over todos can be duplicated.** (unverified) · Status: Open
  - Where: `loadTodayTodos` in [todo_controller.dart](frontend/lib/features/todos/presentation/controllers/todo_controller.dart)
  - Two loads can overlap (e.g. pull-to-refresh during the first load) and both create today's copies. `instanceExistsForDate` exists in the datasource but is unused.

- [ ] **M06 — Forgot Password fails silently.** · Status: Open
  - Where: [forgot_password_screen.dart](frontend/lib/features/auth/presentation/screens/forgot_password_screen.dart)
  - Only the success case is handled; rate-limit or network errors just stop the spinner.

- [ ] **M07 — Min/Max amount filters can't be cleared by emptying the box.** · Status: Open
  - Where: [expense_filter_sheet.dart](frontend/lib/features/expenses/presentation/widgets/expense_filter_sheet.dart), [transaction_filter_sheet.dart](frontend/lib/features/expenses/presentation/widgets/transaction_filter_sheet.dart)
  - `copyWith(minAmount: null)` falls back to the old value; only Reset clears it.

- [ ] **M08 — Amounts aren't validated.** · Status: Open
  - Where: [add_expense_sheet.dart](frontend/lib/features/expenses/presentation/widgets/add_expense_sheet.dart), [add_transaction_sheet.dart](frontend/lib/features/expenses/presentation/widgets/add_transaction_sheet.dart), [budget_dialogs.dart](frontend/lib/features/expenses/presentation/widgets/budget_dialogs.dart)
  - Negative, 0, `NaN`, `Infinity` all accepted. A negative expense lowers totals; a 0 budget shows "Over by ₹X".

- [ ] **M09 — Quick Add Expense shows no categories until the Expenses tab has been opened.** · Status: Open
  - Categories load only from `ExpensesScreen.initState`; shell branches build lazily.

- [ ] **M10 — Expense History search box can look empty while an old query still filters the list.** · Status: Open
  - Where: [expense_history_screen.dart](frontend/lib/features/expenses/presentation/screens/expense_history_screen.dart), [transaction_history_screen.dart](frontend/lib/features/expenses/presentation/screens/transaction_history_screen.dart)
  - `SearchBar` has no controller; the query lives in long-lived state. Transaction search is never reset.

- [ ] **M11 — Setting a budget while viewing a past month changes the current month's budget.** · Status: Open
  - Where: [budget_section.dart](frontend/lib/features/expenses/presentation/widgets/budget_section.dart), [budget_dialogs.dart](frontend/lib/features/expenses/presentation/widgets/budget_dialogs.dart)
  - Dialog pre-fills today's budget and saves with `startDate: DateTime.now()`.

- [ ] **M12 — Editing a vision goal can undo its milestone progress.** · Status: Open
  - Where: [add_goal_sheet.dart:55](frontend/lib/features/vision_board/presentation/widgets/add_goal_sheet.dart#L55)
  - The draft stores `progress`/`status`; restoring an old draft and saving writes e.g. 40% back when all milestones are done.

- [ ] **M13 — A tag filter can get stuck with no way to clear it.** · Status: Open
  - Where: thoughts, life lessons and learnings screens.
  - If the selected tag disappears, the filter row (with "All") is hidden and `selectedTag` is never cleared → "No results" until restart.

- [ ] **M14 — Adding a restaurant or logging a revisit can create duplicates.** · Status: Open
  - Where: [restaurant_remote_datasource.dart:38](frontend/lib/features/restaurants/data/datasources/restaurant_remote_datasource.dart#L38) and `logRevisit`
  - Saves in several separate steps; a failure part-way returns false, and retrying saves the restaurant/visit again.

- [ ] **M15 — A failed photo delete leaves a permanently broken photo.** · Status: Open
  - Where: [photo_remote_datasource.dart:58](frontend/lib/features/photos/data/datasources/photo_remote_datasource.dart#L58)
  - File removed first; if the row delete then fails, the photo returns to the grid with no image.

- [ ] **M16 — Closing the Miscellaneous sheet during a save can cause a duplicate.** · Status: Open
  - Where: [misc_item_sheet.dart:142](frontend/lib/features/miscellaneous/presentation/widgets/misc_item_sheet.dart#L142)
  - `markSubmitted()` runs after the `mounted` check, so the draft survives and reopens with the saved content.

- [ ] **M17 — Adding a milestone and leaving immediately can leave the goal's saved progress stale.** (unverified) · Status: Open
  - Where: [milestones_controller.dart](frontend/lib/features/vision_board/presentation/controllers/milestones_controller.dart)
  - autoDispose notifier sets state after await → throws before `setGoalProgress` runs.

- [ ] **M18 — Search may never find expenses, or count deleted ones.** (unverified) · Status: Open
  - Where: [search_module.dart](frontend/lib/features/search/domain/search_module.dart)
  - Search filters `deleted_at is null` on expenses, but the expenses feature hard-deletes and never uses `deleted_at`. Depending on the schema, expense search always errors, or the dashboard counts rows search treats as deleted.

## Low

**Dates**
- [ ] **L01 — Goal "days left" is one short; the day before the deadline shows "Time's up".** · Open · [vision_goal_details_screen.dart:208](frontend/lib/features/vision_board/presentation/screens/vision_goal_details_screen.dart#L208)
- [ ] **L02 — Goal target date overflows at month end** (31 Jan + "1 month" = 3 Mar). · Open · [add_goal_sheet.dart:105](frontend/lib/features/vision_board/presentation/widgets/add_goal_sheet.dart#L105)
- [ ] **L03 — Miscellaneous cards show the wrong day for items created 00:00–05:30 IST** (UTC not converted to local). · Open · [misc_item_card.dart](frontend/lib/features/miscellaneous/presentation/widgets/misc_item_card.dart)
- [ ] **L04 — Daylight-saving changes break day counting** (health streaks, mood strip, activity history, expense comparison, budget days-left). Doesn't affect India. · Open
- [ ] **L05 — `updated_at` written as local time, read by the DB as UTC** (IST edits stored 5.5h in the future; recency sort wrong). (unverified — only if no DB trigger) · Open · vision_board and thoughts datasources

**Wrong counts or charts**
- [ ] **L06 — A todo carried over for several days counts as several todos** in week/month totals. · Open
- [ ] **L07 — Health streaks stop at 61 days** (only 60 days of logs fetched). (unverified) · Open · [health_controllers.dart](frontend/lib/features/health/presentation/controllers/health_controllers.dart)
- [ ] **L08 — Daily spending chart skips zero-spend days,** so gaps disappear from the line. · Open · [spending_chart_card.dart](frontend/lib/features/dashboard/presentation/widgets/spending_chart_card.dart)

**Saving and deleting**
- [ ] **L09 — Tapping Exercise then Meditation quickly may create duplicate activity rows.** (unverified) · Open
- [ ] **L10 — A restaurant bill typed as "1,200" saves as empty without warning.** · Open · add_restaurant_sheet.dart, revisit_sheet.dart
- [ ] **L11 — Visit History doesn't refresh if the revisit sheet is closed mid-save.** · Open · revisit_sheet.dart
- [ ] **L12 — Photo upload error is shown twice.** · Open · add_photo_sheet.dart + photos_screen.dart
- [ ] **L13 — Failed photo saves leave stray files in the `photos` bucket.** · Open · photo_remote_datasource.dart
- [ ] **L14 — Files of deleted Miscellaneous items are never removed from storage.** · Open · misc_remote_datasource.dart
- [ ] **L15 — Failed swipe-delete (sleep entry, todo without template) removes the row anyway** and trips a Dismissible assertion in debug. · Open
- [ ] **L16 — Failed goal delete still closes the screen with no error shown.** · Open · vision_goal_details_screen.dart
- [ ] **L17 — Tapping Create twice in New Category makes two categories** (and its text controller is never disposed). · Open · add_expense_sheet.dart
- [ ] **L18 — `add_expense_sheet.dart:263` uses the sheet's context after an await** (analyzer `use_build_context_synchronously`); can crash if the sheet closed. · Open

**Sign-in screens**
- [ ] **L19 — If sign-out throws, the error is lost and the user isn't sent to login.** · Open · auth_controller.dart, dialog_utils.dart
- [x] **L20 — Reset Password screen shows raw error text and can be submitted twice.** · **Fixed** (2026-11-17, with H03): loading state + `ErrorHandler.showError`.
- [ ] **L21 — Signup date-of-birth field leaks a TextEditingController every rebuild.** · Open · signup_screen.dart

**Search**
- [ ] **L22 — Some filter-only searches do nothing** (category only; tag + non-taggable modules only). · Open · search_query_builder.dart
- [ ] **L23 — Match highlighting can break on characters like "İ"** (wrong span or RangeError). · Open · highlighted_text.dart
- [ ] **L24 — Leaving Search before results arrive can raise an error in the background.** (unverified) · Open · search_controller.dart

**Navigation and display**
- [ ] **L25 — Restaurant and goal detail screens crash when opened from a link or web refresh** (`state.extra` is null). · Open · [app_router.dart](frontend/lib/core/router/app_router.dart)
- [ ] **L26 — Any progress ring given 0 of 0 crashes** (`NaN` → `.round()` throws). · Open · [percent_ring.dart](frontend/lib/core/widgets/percent_ring.dart)
- [ ] **L27 — Theme choice isn't saved;** app always starts dark (and now also resets on sign-out, see H02). · Open · theme_controller.dart
- [ ] **L28 — Restaurant cover photo can change between refreshes** (unordered embed). (unverified) · Open · restaurants_screen.dart

**Reminders**
- [ ] **L29 — Water reminders stay off after the user allows notifications,** until health settings change. · Open · [reminder_sync_controller.dart](frontend/lib/features/reminders/presentation/controllers/reminder_sync_controller.dart)

**Database (Supabase)**
- [ ] **L30 — Tags migration turns "C#" into "C"** (`btrim(x, ' #')` strips both ends). · Open · [20261117_tags.sql](supabase/migrations/20261117_tags.sql)
- [ ] **L31 — A user can move their milestone onto another user's goal** (update policy doesn't check goal ownership). · Open · [20261117_vision_milestones.sql](supabase/migrations/20261117_vision_milestones.sql)

---

## To check (not bugs yet)

- `frontend/.env` is committed with the Supabase anon key. That's fine only if row-level security is on for **every** table; base-table migrations aren't in this repo, so verify in the Supabase dashboard.

## Notes for whoever picks this up

- Why tests missed H01: the widget tests replace controllers' `build()` with fakes. Prefer `ProviderContainer` tests with a fake datasource (see `controller_initial_load_test.dart`).
- Many controllers are app-wide (non-autoDispose) and load once; that's the root of M03, M04 and M13.
