class AppConstants {
  static const String appName = 'Chronicle';

  // ── Money ──
  static const String currencySymbol = '₹';
  static const String currencyLocale = 'en_IN';

  // ── Auth deep links ──
  /// Where the password-reset email link sends the user back into the app.
  /// The scheme is registered in AndroidManifest.xml and ios/Runner/Info.plist,
  /// and this exact URL must be listed under Supabase → Authentication →
  /// URL Configuration → Redirect URLs.
  static const String passwordResetRedirect = 'com.lavanyaindapure.chronicle://reset-password';

  // ── Storage ──
  static const String photosBucket = 'photos';
  static const String restaurantsBucket = 'restaurants';
  static const String miscBucket = 'misc';

  /// Lifetime of signed image URLs for private storage buckets.
  static const Duration signedUrlTtl = Duration(hours: 1);

  // ── Lists ──
  /// How many recent expenses the Expenses home screen shows before "See all".
  static const int recentExpensesLimit = 8;
}
