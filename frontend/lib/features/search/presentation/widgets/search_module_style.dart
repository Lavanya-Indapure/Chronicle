import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';
import 'package:chronicle/features/search/domain/search_models.dart';
import 'package:chronicle/features/search/domain/search_module.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';

/// Display info and navigation for each [SearchModule].
extension SearchModuleStyle on SearchModule {
  String get label => switch (this) {
        SearchModule.todos => AppStrings.searchModuleTodos,
        SearchModule.expenses => AppStrings.searchModuleExpenses,
        SearchModule.thoughts => AppStrings.searchModuleThoughts,
        SearchModule.learnings => AppStrings.searchModuleLearnings,
        SearchModule.books => AppStrings.searchModuleBooks,
        SearchModule.movies => AppStrings.searchModuleMovies,
        SearchModule.lifeLessons => AppStrings.searchModuleLifeLessons,
        SearchModule.restaurants => AppStrings.searchModuleRestaurants,
        SearchModule.places => AppStrings.searchModulePlaces,
        SearchModule.firstTimes => AppStrings.searchModuleFirstTimes,
        SearchModule.visionBoard => AppStrings.searchModuleGoals,
        SearchModule.misc => AppStrings.searchModuleMisc,
        SearchModule.moods => AppStrings.searchModuleMoods,
      };

  IconData get icon => switch (this) {
        SearchModule.todos => Icons.check_circle_outline_rounded,
        SearchModule.expenses => Icons.receipt_long_rounded,
        SearchModule.thoughts => Icons.lightbulb_rounded,
        SearchModule.learnings => Icons.school_rounded,
        SearchModule.books => Icons.menu_book_rounded,
        SearchModule.movies => Icons.movie_rounded,
        SearchModule.lifeLessons => Icons.psychology_rounded,
        SearchModule.restaurants => Icons.restaurant_rounded,
        SearchModule.places => Icons.place_rounded,
        SearchModule.firstTimes => Icons.auto_awesome_rounded,
        SearchModule.visionBoard => Icons.flag_rounded,
        SearchModule.misc => Icons.widgets_rounded,
        SearchModule.moods => Icons.mood_rounded,
      };

  Color get color => switch (this) {
        SearchModule.todos => AppColors.chartGreen,
        SearchModule.expenses => AppColors.chartOrange,
        SearchModule.thoughts => AppColors.chartLemon,
        SearchModule.learnings => AppColors.chartGreen,
        SearchModule.books => AppColors.chartBlue,
        SearchModule.movies => AppColors.chartCoral,
        SearchModule.lifeLessons => AppColors.chartTeal,
        SearchModule.restaurants => AppColors.chartOrange,
        SearchModule.places => AppColors.chartTeal,
        SearchModule.firstTimes => AppColors.chartLemon,
        SearchModule.visionBoard => AppColors.chartBlue,
        SearchModule.misc => AppColors.chartGreen,
        SearchModule.moods => AppColors.chartOrchid,
      };

  /// Opens the screen that shows [result]: its details screen where one
  /// exists, otherwise the module's list. To-dos and expenses are tabs.
  void open(BuildContext context, SearchResult result) {
    switch (this) {
      case SearchModule.todos:
        context.go('/todos');
      case SearchModule.expenses:
        context.go('/expenses');
      case SearchModule.restaurants:
        context.push('/more/restaurants/details', extra: Restaurant.fromJson(result.row));
      case SearchModule.visionBoard:
        context.push('/more/vision-board/details', extra: VisionGoal.fromJson(result.row));
      case SearchModule.thoughts:
        context.push('/more/thoughts');
      case SearchModule.learnings:
        context.push('/more/learnings');
      case SearchModule.books:
        context.push('/more/books');
      case SearchModule.movies:
        context.push('/more/movies');
      case SearchModule.lifeLessons:
        context.push('/more/life-lessons');
      case SearchModule.places:
        context.push('/more/places-visited');
      case SearchModule.firstTimes:
        context.push('/more/first-time');
      case SearchModule.misc:
        context.push('/more/miscellaneous');
      case SearchModule.moods:
        context.push('/more/mood-board');
    }
  }
}
