import 'package:flutter/material.dart';

/// Lemon circle with the user's initial (More hub card and Profile header).
class ProfileAvatar extends StatelessWidget {
  final String initial;
  final double size;

  const ProfileAvatar({super.key, required this.initial, required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
      child: Text(
        initial,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
