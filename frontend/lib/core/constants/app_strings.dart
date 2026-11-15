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
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String sendResetLink = 'Send Reset Link';
  static const String resetEmailSent = 'Password reset email sent! Please check your inbox.';
  static const String backToLogin = 'Back to Login';

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

  static const String greeting = 'Hello';
  static const String defaultUserName = 'there';
  static const String filterToday = 'Today';
  static const String filterWeek = 'This Week';
  static const String filterMonth = 'This Month';
  static const String totalSpent = 'Total Spent';
  static const String avgPerDay = '/day avg';
  static const String averagePerDay = 'average per day';
  static const String possibleSavings = 'Could Save';
  static const String highestDay = 'Top day';
  static const String yourDay = 'Your Day';
  static const String tasksDone = 'Tasks done';
  static const String currentStreak = 'Current streak';
  static const String bestStreakSuffix = 'Best:';
  static const String days = 'days';
  static const String hydration = 'Hydration';
  static const String hydrationGoalReached = 'Goal reached!';
  static const String hydrationKeepGoing = 'Keep drinking';
  static const String sleep = 'Sleep';
  static const String lastNight = 'Last night';
  static const String noData = 'No data';
  static const String insights = 'Insights';
  static const String dailySpending = 'Daily Spending';
  static const String spentLabel = 'Spent';
  static const String recentActivity = 'Recent Activity';
  static const String learned = 'Learned';
  static const String places = 'Places';
  static const String moods = 'Moods';
  static const String dashboardLoadFailed = 'Failed to load dashboard';
  static const String notEnoughData = 'Log a few expenses to see your trend';
  static const String upNext = 'Up Next';
  static const String allCaughtUp = 'All caught up for today 🎉';
  static const String noTodosToday = 'Nothing planned for today';
  static const String moreTodosPrefix = '+';
  static const String moreTodosSuffix = 'more to do';

  // ── Quick Add ──
  static const String quickAdd = 'Quick Add';
  static const String quickAddExpense = 'Expense';
  static const String quickAddExpenseHint = 'Log something you spent';
  static const String quickAddDebt = 'Debt';
  static const String quickAddDebtHint = 'Money you lent or borrowed';
  static const String quickAddTodo = 'Todo';
  static const String quickAddTodoHint = 'Something to get done';

  // ── Expenses ──
  static const String spentThisMonth = 'Spent This Month';
  static const String thisWeek = 'this week';
  static const String youOwe = 'You Owe';
  static const String owedToYou = 'Owed To You';
  static const String addExpense = 'Add Expense';
  static const String editExpense = 'Edit Expense';
  static const String saveExpense = 'Save Expense';
  static const String deleteExpense = 'Delete Expense';
  static const String deleteExpenseConfirm = 'Delete this expense? This can’t be undone.';
  static const String amount = 'Amount';
  static const String date = 'Date';
  static const String edit = 'Edit';
  static const String category = 'Category';
  static const String previousMonth = 'Previous month';
  static const String nextMonth = 'Next month';
  static const String spentIn = 'Spent in';
  static const String vs = 'vs';
  static const String sameAsLastMonth = 'Same as';
  static const String dailyAvg = 'Daily avg';
  static const String nonEssentialSpend = 'Non-essential';
  static const String budgetLeftSuffix = 'left of';
  static const String budgetOverPrefix = 'Over budget by';
  static const String noExpensesThisMonth = 'No expenses this month.';
  static const String debts = 'Debts';
  static const String addDebt = 'Add Debt';
  static const String budgets = 'Budgets';
  static const String budget = 'Budget';
  static const String categories = 'Categories';
  static const String weeklyBudget = 'Weekly Budget';
  static const String monthlyBudget = 'Monthly Budget';
  static const String noBudgetSet = 'No budget set';
  static const String setBudget = 'Set Budget';
  static const String setWeeklyBudget = 'Set Weekly Budget';
  static const String setMonthlyBudget = 'Set Monthly Budget';
  static const String budgetAmount = 'Budget Amount';
  static const String confirmBudgetTitle = 'Confirm Budget Change';
  static const String confirmBudgetMessage = 'Are you sure you want to update your budget?';
  static const String set = 'Set';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String overBudgetBy = 'Over budget by';
  static const String left = 'left';
  static const String of = 'of';
  static const String transactionsSuffix = 'Transactions';
  static const String transactionSuffix = 'Transaction';
  static const String noCategoryData = 'No spending this month yet';
  static const String uncategorized = 'Uncategorized';
  static const String expenseFallbackTitle = 'Expense';
  static const String savingsInsightTitle = 'Savings Insight';
  static const String savingsInsightPrefix = 'You could have saved';
  static const String savingsInsightSuffix = 'on non-essentials.';
  static const String transactions = 'Transactions';
  static const String seeAll = 'See All';
  static const String search = 'Search';
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String noExpensesYet = 'No expenses logged yet.';
  static const String pendingDebts = 'Pending Debts';
  static const String allSettled = 'All settled! No pending debts.';
  static const String settle = 'Settle';
  static const String confirmSettlementTitle = 'Confirm Settlement';
  static const String confirmSettlementPrefix = 'Mark the debt with';
  static const String confirmSettlementSuffix = 'as settled?';
  static const String lent = 'Lent';
  static const String borrowed = 'Borrowed';
  static const String essential = 'Essential';
  static const String nonEssential = 'Non-essential';

  // ── Todos ──
  static const String addTodo = 'Add Todo';
  static const String editTodo = 'Edit Todo';
  static const String priorityLabel = 'Priority';
  static const String descriptionLabel = 'Description';
  static const String todoTitle = 'Title';
  static const String frequency = 'Frequency';
  static const String saveChanges = 'Save Changes';
  static const String noTodosYet = 'No todos for today';
  static const String addFirstTodo = 'Tap + to add your first todo';
  static const String carriedForward = 'Carried Forward';
  static const String deleteTodoTitle = 'Delete Todo';
  static const String deleteTodoMessage = 'Are you sure you want to delete';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String todayProgress = "Today's Progress";
  static const String doneOf = 'of';
  static const String doneSuffix = 'done';
  static const String todosLeftSuffix = 'left — keep going!';
  static const String todoLeftSuffix = 'left — almost there!';
  static const String allDoneToday = 'All done for today 🎉';
  static const String nothingStarted = "Let's get started";
  static const String deleteTodoAllInstances = 'This removes it and all its repeats.';

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

  // ── Vision Board ──
  static const String searchGoalsHint = 'Search goals or categories…';
  static const String statusAll = 'All';
  static const String statusInProgress = 'In Progress';
  static const String statusCompleted = 'Completed';
  static const String statusNotStarted = 'Not Started';
  static const String newGoal = 'New Goal';
  static const String favoritesOnly = 'Favourites only';
  static const String sortBy = 'Sort';
  static const String sortRecency = 'Recently Updated';
  static const String sortDeadline = 'Closest Deadline';
  static const String sortProgress = 'Highest Progress';
  static const String noDeadline = 'No deadline';
  static const String visionEmptyTitle = 'Your vision board is empty';
  static const String visionEmptyMessage = 'Define your goals and manifest your future!';
  static const String visionNoMatchesTitle = 'No goals match';
  static const String visionNoMatchesMessage = 'Try a different search or filter.';
  static const String addFirstGoal = 'Add your first goal';

  // ── Restaurants ──
  static const String visitSingular = 'visit';
  static const String visitPlural = 'visits';
  static const String address = 'Address';
  static const String visitHistory = 'Visit History';
  static const String noVisitsYet = 'No visits logged yet.';
  static const String visitedAgain = 'Visited Again';
  static const String favorite = 'Favourite';

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
