import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/coming_soon_screen.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: AppStrings.expensesLabel,
      icon: Icons.account_balance_wallet_outlined,
    );
  }
}
