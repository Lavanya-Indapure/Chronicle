import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/coming_soon_screen.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: AppStrings.healthLabel,
      icon: Icons.favorite_outline,
    );
  }
}
