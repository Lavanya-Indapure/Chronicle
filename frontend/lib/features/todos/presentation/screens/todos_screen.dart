import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/coming_soon_screen.dart';

class TodosScreen extends StatelessWidget {
  const TodosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: AppStrings.todosLabel,
      icon: Icons.check_circle_outline,
    );
  }
}
