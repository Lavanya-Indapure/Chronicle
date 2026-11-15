import 'package:flutter/material.dart';

/// Section title with an optional trailing value or action
/// (e.g. "Transactions ........ ₹1,450" or "Recent ...... See All").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: title,
              style: theme.textTheme.titleLarge,
              children: [
                if (subtitle != null)
                  TextSpan(text: '  $subtitle', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
