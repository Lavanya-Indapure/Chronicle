import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';

/// Platform values stored on movies, with their display label/icon/colour.
abstract final class MoviePlatform {
  static const theatre = 'theatre';
  static const digital = 'mobile-laptop';

  static String label(String platform) =>
      platform == theatre ? AppStrings.platformTheatre : AppStrings.platformDigital;

  static IconData icon(String platform) =>
      platform == theatre ? Icons.theaters_rounded : Icons.laptop_mac_rounded;

  static Color color(String platform) => platform == theatre ? AppColors.chartOrchid : AppColors.chartBlue;
}
