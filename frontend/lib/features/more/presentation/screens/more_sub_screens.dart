import 'package:flutter/material.dart';
import 'package:chronicle/core/widgets/coming_soon_screen.dart';
import 'package:chronicle/core/constants/app_strings.dart';

class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});
  @override
  Widget build(BuildContext context) => const ComingSoonScreen(title: AppStrings.photosLabel, icon: Icons.photo_library_outlined);
}

class RestaurantsScreen extends StatelessWidget {
  const RestaurantsScreen({super.key});
  @override
  Widget build(BuildContext context) => const ComingSoonScreen(title: AppStrings.restaurantsLabel, icon: Icons.restaurant_outlined);
}

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});
  @override
  Widget build(BuildContext context) => const ComingSoonScreen(title: AppStrings.moviesLabel, icon: Icons.movie_outlined);
}

class ThoughtsScreen extends StatelessWidget {
  const ThoughtsScreen({super.key});
  @override
  Widget build(BuildContext context) => const ComingSoonScreen(title: AppStrings.thoughtsLabel, icon: Icons.lightbulb_outline);
}

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});
  @override
  Widget build(BuildContext context) => const ComingSoonScreen(title: AppStrings.booksLabel, icon: Icons.menu_book_outlined);
}

class VisionBoardScreen extends StatelessWidget {
  const VisionBoardScreen({super.key});
  @override
  Widget build(BuildContext context) => const ComingSoonScreen(title: AppStrings.visionBoardLabel, icon: Icons.dashboard_customize_outlined);
}

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
