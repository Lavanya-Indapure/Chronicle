/// Where and how each searchable module is queried.
class SearchModuleSpec {
  final String table;
  final String select;

  /// Columns matched (case-insensitively) against the search text.
  final List<String> textColumns;

  /// The module's natural date: used for the date-range filter and to order
  /// results newest first.
  final String dateColumn;

  /// Table has `deleted_at` (soft delete) — deleted rows are excluded.
  final bool softDelete;

  /// Table has a `tags text[]` column.
  final bool taggable;

  /// Extra equality filters, e.g. only active to-dos.
  final Map<String, Object> equals;

  const SearchModuleSpec({
    required this.table,
    required this.select,
    required this.textColumns,
    required this.dateColumn,
    this.softDelete = false,
    this.taggable = false,
    this.equals = const {},
  });
}

/// Every module the global search covers, in display order.
enum SearchModule {
  todos(SearchModuleSpec(
    table: 'todo_templates',
    select: 'id,title,description,recurrence_type,created_at',
    textColumns: ['title', 'description'],
    dateColumn: 'created_at',
    softDelete: true,
    equals: {'is_active': true},
  )),
  expenses(SearchModuleSpec(
    table: 'expenses',
    select: 'id,description,amount,expense_date,category_id,categories(name)',
    textColumns: ['description'],
    dateColumn: 'expense_date',
    softDelete: true,
  )),
  thoughts(SearchModuleSpec(
    table: 'thoughts',
    select: 'id,content,tags,created_at',
    textColumns: ['content'],
    dateColumn: 'created_at',
    taggable: true,
  )),
  learnings(SearchModuleSpec(
    table: 'learnings',
    select: 'id,title,description,source,category,tags,log_date',
    textColumns: ['title', 'description', 'source'],
    dateColumn: 'log_date',
    taggable: true,
  )),
  books(SearchModuleSpec(
    table: 'books',
    select: 'id,name,author,takeaways,status,tags,created_at',
    textColumns: ['name', 'author', 'takeaways'],
    dateColumn: 'created_at',
    taggable: true,
  )),
  movies(SearchModuleSpec(
    table: 'movies',
    select: 'id,name,comments,takeaways,platform,tags,watch_date',
    textColumns: ['name', 'comments', 'takeaways'],
    dateColumn: 'watch_date',
    taggable: true,
  )),
  lifeLessons(SearchModuleSpec(
    table: 'life_lessons',
    select: 'id,title,content,tags,created_at',
    textColumns: ['title', 'content'],
    dateColumn: 'created_at',
    softDelete: true,
    taggable: true,
  )),
  restaurants(SearchModuleSpec(
    table: 'restaurants',
    // Full row: tapping a result opens the details screen, which needs it.
    select: '*, restaurant_photos(*)',
    textColumns: ['name', 'address', 'latest_food_items', 'latest_notes'],
    dateColumn: 'updated_at',
  )),
  places(SearchModuleSpec(
    table: 'places_visited',
    select: 'id,place_name,city,description,visit_date',
    textColumns: ['place_name', 'city', 'description'],
    dateColumn: 'visit_date',
  )),
  firstTimes(SearchModuleSpec(
    table: 'first_times',
    select: 'id,title,description,location,log_date',
    textColumns: ['title', 'description', 'location'],
    dateColumn: 'log_date',
  )),
  visionBoard(SearchModuleSpec(
    table: 'vision_board',
    // Full row: tapping a result opens the goal details screen.
    select: '*',
    textColumns: ['title', 'description', 'plan', 'category'],
    dateColumn: 'created_at',
  )),
  misc(SearchModuleSpec(
    table: 'misc_items',
    select: 'id,title,content,storage_path,created_at',
    textColumns: ['title', 'content'],
    dateColumn: 'created_at',
    softDelete: true,
  )),
  moods(SearchModuleSpec(
    table: 'moods',
    select: 'id,mood,note,log_date',
    textColumns: ['note', 'mood'],
    dateColumn: 'log_date',
  ));

  final SearchModuleSpec spec;

  const SearchModule(this.spec);

  bool get taggable => spec.taggable;

  static List<SearchModule> get taggableModules => values.where((m) => m.taggable).toList();
}
