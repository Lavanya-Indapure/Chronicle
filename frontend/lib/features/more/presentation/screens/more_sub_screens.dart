import 'package:flutter/material.dart';
import 'package:chronicle/core/widgets/coming_soon_screen.dart';
import 'package:chronicle/core/constants/app_strings.dart';

// Removed duplicate PhotosScreen placeholder

// Removed duplicate RestaurantsScreen placeholder

// Removed duplicate MoviesScreen placeholder

// Removed duplicate ThoughtsScreen placeholder

// Removed duplicate BooksScreen placeholder


class LifeLessonsScreen extends StatelessWidget {
  const LifeLessonsScreen({super.key});
  @override
  Widget build(BuildContext context) => const ComingSoonScreen(title: AppStrings.lifeLessonsLabel, icon: Icons.school_outlined);
}

class LearningsScreen extends StatelessWidget {
  const LearningsScreen({super.key});
  @override
  Widget build(BuildContext context) => const ComingSoonScreen(title: AppStrings.learningsLabel, icon: Icons.auto_stories_outlined);
}

class FirstTimeExperiencesScreen extends StatelessWidget {
  const FirstTimeExperiencesScreen({super.key});
  @override
  Widget build(BuildContext context) => const ComingSoonScreen(title: AppStrings.firstTimeLabel, icon: Icons.star_outline);
}

class MoodBoardScreen extends StatelessWidget {
  const MoodBoardScreen({super.key});
  @override
  Widget build(BuildContext context) => const ComingSoonScreen(title: AppStrings.moodBoardLabel, icon: Icons.mood_outlined);
}

class PlacesVisitedScreen extends StatelessWidget {
  const PlacesVisitedScreen({super.key});
  @override
  Widget build(BuildContext context) => const ComingSoonScreen(title: AppStrings.placesVisitedLabel, icon: Icons.place_outlined);
}

class MiscellaneousScreen extends StatelessWidget {
  const MiscellaneousScreen({super.key});
  @override
  Widget build(BuildContext context) => const ComingSoonScreen(title: AppStrings.miscellaneousLabel, icon: Icons.widgets_outlined);
}
