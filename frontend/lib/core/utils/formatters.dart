import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_constants.dart';

/// Shared display formatters so money and dates look the same everywhere.
abstract final class AppFormatters {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: AppConstants.currencyLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: AppConstants.currencyLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  /// ₹12,345
  static String currency(double amount) => _currency.format(amount);

  /// ₹12K — for chart axes and tight spaces.
  static String compactCurrency(double amount) => _compact.format(amount);

  /// 42%
  static String percent(double fraction) => '${(fraction * 100).round()}%';

  /// November 2026
  static String monthYear(DateTime date) => DateFormat('MMMM yyyy').format(date);

  /// November
  static String monthName(DateTime date) => DateFormat('MMMM').format(date);

  /// Nov
  static String shortMonth(DateTime date) => DateFormat('MMM').format(date);

  /// Nov 15
  static String shortDate(DateTime date) => DateFormat('MMM d').format(date);

  /// 15 Nov
  static String dayMonth(DateTime date) => DateFormat('d MMM').format(date);

  /// 22 Mar 2026
  static String dayMonthYear(DateTime date) => DateFormat('d MMM yyyy').format(date);

  /// Saturday, 15 Nov
  static String weekdayDayMonth(DateTime date) => DateFormat('EEEE, d MMM').format(date);

  /// 7h 20m
  static String duration(Duration d) => '${d.inHours}h ${d.inMinutes.remainder(60)}m';
}
