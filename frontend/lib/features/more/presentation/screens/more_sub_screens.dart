import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/empty_state.dart';

class LifeLessonsScreen extends StatelessWidget {
  const LifeLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.lifeLessonsLabel)),
      body: const EmptyState(
        icon: Icons.psychology_rounded,
        title: AppStrings.comingSoon,
        message: AppStrings.lifeLessonsComingSoon,
      ),
    );
  }
}

class MiscellaneousScreen extends StatelessWidget {
  const MiscellaneousScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.miscellaneousLabel)),
      body: const EmptyState(
        icon: Icons.widgets_rounded,
        title: AppStrings.comingSoon,
        message: AppStrings.miscComingSoon,
      ),
    );
  }
}
