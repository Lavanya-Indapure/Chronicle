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
  static const String logoutConfirm = 'Are you sure you want to log out?';

  // ── Drafts ──
  static const String draftRestored = 'Draft restored';
  static const String discardDraft = 'Discard';
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

  // ── Todo heatmap ──
  static const String todoHeatmapTitle = 'Consistency';
  static const String todoHeatmapWeeksSuffix = 'weeks';
  static const String todoHeatmapLess = 'Less';
  static const String todoHeatmapMore = 'More';
  static const String todoHeatmapNothingDue = 'nothing due';
  static const String todoHeatmapDone = 'done';
  static const String todoHeatmapToday = 'today';
  static const String todoHeatmapSemantics = 'Todo completion heatmap';

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
  static const String pickMonth = 'Choose month';
  static const String previousYear = 'Previous year';
  static const String nextYear = 'Next year';
  static const String thisMonthShortcut = 'This month';
  static const String spentIn = 'Spent in';
  static const String vs = 'vs';
  static const String sameAsLastMonth = 'Same as';
  static const String dailyAvg = 'Daily avg';
  static const String nonEssentialSpend = 'Non-essential';
  static const String budgetLeftSuffix = 'left of';
  static const String budgetOverPrefix = 'Over budget by';
  static const String noExpensesThisMonth = 'No expenses this month.';
  static const String debts = 'Debts';
  static const String setBudgetCta = 'Set a budget';
  static const String monthly = 'Monthly';
  static const String weekly = 'Weekly';
  static const String dailyAvgLower = 'daily avg';
  static const String nonEssentialLower = 'non-essential';
  static const String allCategories = 'All categories';
  static const String whereItWent = 'Where it went';
  static const String owedLower = 'owed to you';
  static const String oweLower = 'you owe';
  static const String noPendingDebts = 'All settled';
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

  // ── More hub ──
  // (strings for the More tab redesign go here)
  static const String moreSectionMemories = 'Memories';
  static const String moreSectionMedia = 'Collections';
  static const String moreSectionMind = 'Mind & Growth';
  static const String account = 'Account';
  static const String logOut = 'Log out';
  static const String viewProfile = 'View profile';
  static const String profileEmail = 'Email';
  static const String memberSince = 'Member since';
  static const String unknownUser = 'Chronicle user';
  static const String noEmail = 'No email on file';
  static const String appearance = 'Appearance';
  static const String themeLabel = 'Theme';
  static const String themeSystem = 'System';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String themeHint = 'System follows your phone’s light/dark setting.';
  static const String about = 'About';
  static const String version = 'Version';
  static const String appVersion = '1.0.0';
  // Books
  static const String myLibrary = 'My Library';
  static const String searchBooksHint = 'Search title or author…';
  static const String bookStatusReading = 'Reading';
  static const String bookStatusCompleted = 'Completed';
  static const String addBook = 'Add Book';
  static const String editBook = 'Edit Book';
  static const String bookTitle = 'Book title';
  static const String bookTitleRequired = 'Title is required';
  static const String authorOptional = 'Author (optional)';
  static const String status = 'Status';
  static const String rating = 'Rating';
  static const String clearRating = 'Clear rating';
  static const String keyTakeaways = 'Key takeaways';
  static const String markFavorite = 'Mark as favourite';
  static const String addToLibrary = 'Add to Library';
  static const String deleteBookTitle = 'Remove book?';
  static const String deleteBookMessage = 'This removes the book and its notes from your library.';
  static const String libraryEmptyTitle = 'Your library is empty';
  static const String libraryEmptyMessage = 'Track what you read and the ideas worth keeping.';
  static const String libraryNoMatchesTitle = 'Nothing matches';
  static const String libraryNoMatchesMessage = 'Try a different search or filter.';
  // Movies
  static const String moviesWatched = 'Movies';
  static const String searchMoviesHint = 'Search movies…';
  static const String platformTheatre = 'Theatre';
  static const String platformDigital = 'Streaming';
  static const String logMovie = 'Log Movie';
  static const String editMovie = 'Edit Movie';
  static const String movieName = 'Movie name';
  static const String movieNameRequired = 'Name is required';
  static const String watchedOn = 'Watched on';
  static const String platform = 'Where';
  static const String ticketCost = 'Ticket cost';
  static const String ticketCostRequired = 'Add the ticket cost';
  static const String commentsOptional = 'Comments (optional)';
  static const String takeawaysOptional = 'Takeaways (optional)';
  static const String deleteMovieTitle = 'Delete this log?';
  static const String deleteMovieMessage = 'This removes the movie from your watch history.';
  static const String moviesEmptyTitle = 'No movies logged yet';
  static const String moviesEmptyMessage = 'Keep track of what you watch in theatres and at home.';
  static const String moviesThisYear = 'this year';
  static const String theatreSpend = 'spent at theatres';
  static const String moviesCountSuffix = 'movies';
  static const String movieCountSuffix = 'movie';

  // ── Collections: Books, Movies, Restaurants, Photos ──
  // (strings for the collections redesign go here)
  // Restaurants
  static const String searchRestaurantsHint = 'Search restaurant or food…';
  static const String addRestaurant = 'Add Restaurant';
  static const String logRestaurant = 'Log Restaurant';
  static const String restaurantName = 'Restaurant name';
  static const String billAmount = 'Bill amount';
  static const String whatYouAte = 'What you ate';
  static const String notesLabel = 'Notes';
  static const String visitNotes = 'Visit notes';
  static const String saveRestaurant = 'Save Restaurant';
  static const String logVisit = 'Log Visit';
  static const String newVisitTo = 'New visit to';
  static const String visitLogged = 'Visit logged';
  static const String ratingLabel = 'Rating';
  static const String ratingForVisit = 'Rating for this visit';
  static const String markAsFavourite = 'Mark as favourite';
  static const String fieldRequired = 'Required';
  static const String photosCount = 'Photos';
  static const String addPhotos = 'Add photos';
  static const String removePhoto = 'Remove photo';
  static const String filterAllRestaurants = 'All';
  static const String filterFavourites = 'Favourites';
  static const String filterTopRated = 'Top rated';
  static const String sortLatestVisited = 'Latest Visited';
  static const String sortHighestRated = 'Highest Rated';
  static const String sortMostVisited = 'Most Visited';
  static const String noRestaurantsTitle = 'No restaurants yet';
  static const String noRestaurantsMessage = 'Start tracking your dining adventures!';
  static const String addFirstRestaurant = 'Add your first restaurant';
  static const String noMatchesTitle = 'No matches';
  static const String noMatchesMessage = 'Try a different search or filter.';
  // Photos
  static const String addPhoto = 'Add Photo';
  static const String addNewMemory = 'Add New Memory';
  static const String tapToSelectImage = 'Tap to choose a photo';
  static const String changePhoto = 'Change photo';
  static const String captionOptional = 'Caption (optional)';
  static const String photoDate = 'Photo date';
  static const String saveMemory = 'Save Memory';
  static const String gallery = 'Gallery';
  static const String camera = 'Camera';
  static const String photoUploaded = 'Photo saved';
  static const String photoUploadFailed = 'Failed to upload photo';
  static const String pickImageFailed = 'Couldn’t open the photo picker';
  static const String deletePhotoTitle = 'Delete photo?';
  static const String deletePhotoMessage = 'This permanently removes the photo and its caption.';
  static const String noPhotosTitle = 'No photos yet';
  static const String noPhotosMessage = 'Capture your memories!';
  static const String addFirstPhoto = 'Add your first photo';
  static const String photoSingular = 'photo';
  static const String photoPlural = 'photos';

  // ── Journaling: Thoughts, Learnings, First-times, Moods, Places ──
  // (strings for the journaling redesign go here)
  // Shared
  static const String journalDate = 'Date';
  static const String journalSave = 'Save';
  static const String journalDeleteTitle = 'Delete entry?';
  static const String journalDeleteMessage = 'This can’t be undone.';
  static const String journalRating = 'Rating';
  static const String journalNoResultsTitle = 'Nothing matches';
  static const String journalNoResultsMessage = 'Try a different search or filter.';
  static const String journalAll = 'All';
  // Thoughts
  static const String thoughtsTitle = 'Thoughts & Quotes';
  static const String thoughtsSearchHint = 'Search thoughts or tags…';
  static const String thoughtsFavoritesOnly = 'Favourites only';
  static const String thoughtsEmptyTitle = 'No thoughts captured yet';
  static const String thoughtsEmptyMessage = 'Save quotes and ideas worth remembering.';
  static const String thoughtsAdd = 'New Thought';
  static const String thoughtsAddFirst = 'Capture your first thought';
  static const String thoughtCaptureTitle = 'Capture Thought';
  static const String thoughtEditTitle = 'Edit Thought';
  static const String thoughtContentLabel = 'Quote or idea';
  static const String thoughtContentHint = 'What’s on your mind?';
  static const String thoughtContentRequired = 'Please write something';
  static const String thoughtTagsLabel = 'Tags (comma separated)';
  static const String thoughtTagsHint = 'motivation, life, deep';
  static const String thoughtSave = 'Save Thought';
  static const String thoughtUpdate = 'Save Changes';
  static const String thoughtDeleteTitle = 'Delete thought?';
  static const String thoughtFavorite = 'Favourite';
  // Learnings
  static const String learningsTitle = 'Learnings';
  static const String learningsSearchHint = 'Search learnings…';
  static const String learningsEmptyTitle = 'No learnings logged yet';
  static const String learningsEmptyMessage = 'Record the things you discover along the way.';
  static const String learningsAdd = 'New Learning';
  static const String learningsAddFirst = 'Log your first learning';
  static const String learningNewTitle = 'New Learning';
  static const String learningTitleLabel = 'What did you learn?';
  static const String learningDetailsLabel = 'Details (optional)';
  static const String learningSourceLabel = 'Source (e.g. book, friend)';
  static const String learningCategory = 'Category';
  static const String learningUsefulness = 'Usefulness';
  static const String learningSave = 'Save Learning';
  static const String learningSourcePrefix = 'From';
  static const String learningCatFinance = 'Finance';
  static const String learningCatTechnology = 'Technology';
  static const String learningCatLife = 'Life';
  static const String learningCatFood = 'Food';
  static const String learningCatTravel = 'Travel';
  static const String learningCatOther = 'Other';
  // First-times
  static const String firstsTitle = 'First Times';
  static const String firstsEmptyTitle = 'Every first is special';
  static const String firstsEmptyMessage = 'Record your life’s milestones here.';
  static const String firstsAdd = 'Log a First';
  static const String firstsAddFirst = 'Log your first milestone';
  static const String firstsTotalSuffix = 'firsts';
  static const String firstsThisYearSuffix = 'this year';
  static const String firstNewTitle = 'Log a First';
  static const String firstTitleLabel = 'What was it?';
  static const String firstDescriptionLabel = 'What happened? (optional)';
  static const String firstLocationLabel = 'Where? (optional)';
  static const String firstFeeling = 'How did you feel?';
  static const String firstSave = 'Save Milestone';
  static const String feelingHappy = 'Happy';
  static const String feelingNervous = 'Nervous';
  static const String feelingExcited = 'Excited';
  static const String feelingAmazed = 'Amazed';
  static const String feelingScared = 'Scared';
  // Moods
  static const String moodTitle = 'Mood Board';
  static const String moodOverallVibe = 'Overall vibe';
  static const String moodBasedOnPrefix = 'Based on';
  static const String moodEntriesSuffix = 'entries';
  static const String moodEntrySuffix = 'entry';
  static const String moodNoEntries = 'Log a mood to see your vibe';
  static const String moodLast14Days = 'Last 14 days';
  static const String moodHowAreYou = 'How are you today?';
  static const String moodTodayPrefix = 'Today:';
  static const String moodTapToChange = 'tap a mood to change it';
  static const String moodNoteHint = 'Add a quick note (optional)…';
  static const String moodLog = 'Log Mood';
  static const String moodHistory = 'History';
  static const String moodHistoryEmpty = 'Your mood history will appear here.';
  static const String moodHappy = 'Happy';
  static const String moodExcited = 'Excited';
  static const String moodNeutral = 'Neutral';
  static const String moodTired = 'Tired';
  static const String moodStressed = 'Stressed';
  static const String moodSad = 'Sad';
  // Places
  static const String placesTitle = 'Places Visited';
  static const String placesSearchHint = 'Search places or cities…';
  static const String placesEmptyTitle = 'Exploring the world?';
  static const String placesEmptyMessage = 'Start logging the places you visit.';
  static const String placesAdd = 'Log a Place';
  static const String placesAddFirst = 'Log your first place';
  static const String placesCountSuffix = 'places';
  static const String placeCountSuffix = 'place';
  static const String citiesCountSuffix = 'cities';
  static const String cityCountSuffix = 'city';
  static const String placeNewTitle = 'Log a Visit';
  static const String placeNameLabel = 'Place name';
  static const String placeCityLabel = 'City / region (optional)';
  static const String placeDetailsLabel = 'Experience details (optional)';
  static const String placeSave = 'Save Place';

  // ── Life lessons ──
  static const String lifeLessonsSearchHint = 'Search lessons or tags…';
  static const String lifeLessonsEmptyTitle = 'What has life taught you?';
  static const String lifeLessonsEmptyMessage = 'Write down the lessons worth carrying forward.';
  static const String lifeLessonsAdd = 'New Lesson';
  static const String lifeLessonsAddFirst = 'Write your first lesson';
  static const String lifeLessonNewTitle = 'New Life Lesson';
  static const String lifeLessonEditTitle = 'Edit Life Lesson';
  static const String lifeLessonDeleteTitle = 'Delete lesson?';
  static const String lifeLessonTitleLabel = 'Title (optional)';
  static const String lifeLessonTitleHint = 'Sum it up in a few words';
  static const String lifeLessonContentLabel = 'The lesson';
  static const String lifeLessonContentHint = 'What happened, and what did it teach you?';
  static const String lifeLessonContentRequired = 'Please write the lesson';
  static const String lifeLessonTagsLabel = 'Tags (comma separated)';
  static const String lifeLessonTagsHint = 'patience, career, relationships';
  static const String lifeLessonSave = 'Save Lesson';
  static const String lifeLessonUpdate = 'Save Changes';

  // ── Miscellaneous ──
  static const String miscSearchHint = 'Search notes…';
  static const String miscEmptyTitle = 'A home for everything else';
  static const String miscEmptyMessage = 'Keep notes and pictures that don’t fit anywhere else.';
  static const String miscAdd = 'New Item';
  static const String miscAddFirst = 'Add your first item';
  static const String miscNewTitle = 'New Item';
  static const String miscEditTitle = 'Edit Item';
  static const String miscDeleteTitle = 'Delete item?';
  static const String miscTitleLabel = 'Title (optional)';
  static const String miscContentLabel = 'Note (optional)';
  static const String miscContentHint = 'Write anything…';
  static const String miscAddImage = 'Tap to add a picture (optional)';
  static const String miscRemoveImage = 'Remove picture';
  static const String miscNeedsContent = 'Add a note or a picture';
  static const String miscSave = 'Save Item';
  static const String miscUpdate = 'Save Changes';

  // ── Health ──
  static const String save = 'Save';
  static const String saving = 'Saving…';
  static const String healthTodayTitle = 'Water today';
  static const String healthDailyTracking = 'Daily tracking';
  static const String healthSettingsTitle = 'Health settings';
  static const String healthRemindersToggle = 'Water reminders';
  static const String healthRemindersHint = 'A notification at each glass time';
  static const String healthDayStart = 'First reminder';
  static const String healthDayEnd = 'Last reminder';
  static const String healthInterval = 'Remind me every';
  static const String healthGlassesPerDay = 'glasses a day';
  static const String healthNoSlotsWarning = 'The last reminder must be after the first one.';
  static const String healthSleepGoal = 'Nightly sleep goal';
  static const String healthLess = 'Less';
  static const String healthMore = 'More';
  static const String healthMinutesShort = 'm';
  static const String healthDaysShort = 'd';

  static const String hydrationToday = 'Today';
  static const String hydrationGlasses = 'glasses';
  static const String hydrationNextAt = 'Next at';
  static const String hydrationLogGlass = 'Log a glass';
  static const String hydrationSchedule = "Today's schedule";
  static const String hydrationScheduleHint = 'Tap to log · long-press to skip · tap again to undo';
  static const String hydrationNoSlots = 'No reminder times set. Adjust them in health settings.';
  static const String hydrationDone = 'done';
  static const String hydrationSkipped = 'skipped';
  static const String hydrationPending = 'not logged';

  static const String sleepLastNight = 'Last night';
  static const String sleepStart = 'Start sleep';
  static const String sleepWakeUp = "I'm awake";
  static const String sleepSleepingSince = 'Asleep since';
  static const String sleepSoFar = 'so far';
  static const String sleepGoodNight = 'Good night — tap "I\'m awake" when you get up.';
  static const String sleepStartHint = 'Tap "Start sleep" at bedtime, or add a night with +.';
  static const String sleepGoalMet = 'Goal met';
  static const String sleepBelowGoal = 'Below goal';
  static const String sleepShortOfGoal = 'short of your goal';
  static const String sleepThisWeek = 'Last 7 nights';
  static const String sleepAvgPerNight = 'avg / night';
  static const String sleepWeekAvg = '7-day avg';
  static const String sleepGoal = 'Goal';
  static const String sleepHoursShort = 'h';
  static const String sleepWeeklyWarningPrefix = 'Your weekly average is below your';
  static const String sleepWeeklyWarningSuffix = 'goal.';
  static const String sleepHistory = 'History';
  static const String sleepHistoryEmpty = 'No nights logged in the last 30 days.';
  static const String sleepAddManual = 'Log a night';
  static const String sleepBedtime = 'Went to bed';
  static const String sleepWakeTime = 'Woke up';
  static const String sleepTotal = 'Total';
  static const String sleepErrorOrder = 'Wake-up time must be after bedtime.';
  static const String sleepErrorTooLong = 'That is longer than 18 hours — check AM/PM.';
  static const String sleepErrorFuture = "Wake-up time can't be in the future.";
  static const String sleepWarningInsight = 'Your sleep this week is averaging below your goal.';

  static const String activityTitle = 'Activity';
  static const String activityToday = 'Today';
  static const String activityExercise = 'Exercise';
  static const String activityMeditation = 'Meditation';
  static const String activityDoneToday = 'Done today';
  static const String activityTapToLog = 'Tap to mark done';
  static const String activityDoneTodaySuffix = 'done today';
  static const String activityDayStreak = 'day streak';
  static const String activityDaysStreak = 'day streak';
  static const String activityStreakSuffix = 'streaks';
  static const String activityNotesHint = 'Notes — what did you do?';
  static const String activityLastFourWeeks = 'Last 4 weeks';
  static const String activityDaysOutOf = 'of';

  // ── Reminders ──
  static const String reminderHydrationChannel = 'Water reminders';
  static const String reminderHydrationChannelDescription = 'Reminders to drink a glass of water';
  static const String reminderHydrationTitle = 'Time for a glass of water 💧';
  static const String reminderHydrationBody = 'Tap to log it in Chronicle.';
  static const String reminderDuesChannel = 'Dues reminders';
  static const String reminderDuesChannelDescription = 'Weekly reminder about money lent or borrowed';
  static const String reminderDuesTitle = 'Dues to settle';
  static const String reminderDuePending = 'pending';
  static const String reminderDuesPending = 'pending';
  static const String reminderDuesToCollect = 'to collect';
  static const String reminderDuesToPay = 'to pay';

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
