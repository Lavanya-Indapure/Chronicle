import 'package:flutter/material.dart';

/// Bounds for `showDateRangePicker` that always contain [initial].
///
/// The picker asserts that its initial range lies within firstDate..lastDate,
/// so a filter such as "this month" (ending after today) or one starting
/// before [first] would crash it. The default bounds are widened just enough
/// to fit [initial].
DateTimeRange pickerBounds({required DateTime first, required DateTime last, DateTimeRange? initial}) {
  if (initial == null) return DateTimeRange(start: first, end: last);
  return DateTimeRange(
    start: initial.start.isBefore(first) ? initial.start : first,
    end: initial.end.isAfter(last) ? initial.end : last,
  );
}
