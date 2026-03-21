/// Chronicle — Centralized User-Facing Strings
abstract final class AppStrings {
  // ── App ──
  static const String appName = 'Chronicle';
  static const String appTagline = 'Your Personal Intelligence System';

  // ── Auth ──
  static const String login = 'Login';
  static const String signUp = 'Sign Up';
  static const String createAccount = 'Create Account';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String dateOfBirth = 'Date of Birth (Optional)';
  static const String tapToSelect = 'Tap to select';
  static const String loginSuccessful = 'Login successful!';
  static const String accountCreated = 'Account created! Please check your email to verify.';
  static const String noAccount = "Don't have an account? ";
  static const String haveAccount = 'Already have an account? ';
  static const String selectDob = 'Select Date of Birth';
  static const String logout = 'Logout';

  // ── Navigation (Bottom Tabs) ──
  static const String dashboardLabel = 'Dashboard';
  static const String todosLabel = 'Todos';
  static const String expensesLabel = 'Expenses';
  static const String healthLabel = 'Health';
  static const String moreLabel = 'More';

  // ── Dashboard ──
  static const String welcomeBack = 'Welcome back 👋';
  static const String dashboardSubtitle = 'Here\'s your day at a glance';
  static const String streakLabel = 'Streak';
  static const String comingSoon = 'Coming Soon';

  // ── More Sub-features ──
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  static const String photosLabel = 'Photos';
  static const String restaurantsLabel = 'Restaurants';
  static const String moviesLabel = 'Movies';
  static const String thoughtsLabel = 'Thoughts';
  static const String booksLabel = 'Books';
  static const String visionBoardLabel = 'Vision Board';
  static const String lifeLessonsLabel = 'Life Lessons';
  static const String learningsLabel = 'Learnings';
  static const String firstTimeLabel = 'First Time Experiences';
  static const String moodBoardLabel = 'Mood Board';
  static const String placesVisitedLabel = 'Places Visited';
  static const String miscellaneousLabel = 'Miscellaneous';

  // ── Validation ──
  static const String requiredEmail = 'Please enter your email';
  static const String invalidEmail = 'Please enter a valid email';
  static const String requiredPassword = 'Please enter your password';
  static const String requiredFirstName = 'Please enter your first name';
  static const String requiredLastName = 'Please enter your last name';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordMismatch = 'Passwords do not match';

  // ── Errors ──
  static const String loginFailed = 'Login failed';
  static const String signupFailed = 'Signup failed';
  static const String unknownError = 'An unexpected error occurred';
}
