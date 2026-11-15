class AppConstants {
  static const String appName = 'Chronicle';

  // ── Money ──
  static const String currencySymbol = '₹';
  static const String currencyLocale = 'en_IN';

  // ── Storage ──
  static const String photosBucket = 'photos';
  static const String restaurantsBucket = 'restaurants';

  /// Lifetime of signed image URLs for private storage buckets.
  static const Duration signedUrlTtl = Duration(hours: 1);

  // ── Lists ──
  /// How many recent expenses the Expenses home screen shows before "See all".
  static const int recentExpensesLimit = 8;
}
