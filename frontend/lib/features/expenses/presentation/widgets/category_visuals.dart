import 'package:flutter/material.dart';
import 'package:chronicle/core/theme/app_colors.dart';

/// Picks an icon and palette colour for an expense category.
///
/// Categories don't store a usable icon/colour yet, so icons are matched by
/// keywords in the name and colours are assigned by rank in the palette.
abstract final class CategoryVisuals {
  static const IconData fallbackIcon = Icons.category_outlined;

  static const List<(List<String>, IconData)> _keywordIcons = [
    (['rent', 'home', 'house', 'emi', 'utilit', 'bill'], Icons.home_rounded),
    (['food', 'grocer', 'restaurant', 'dining', 'eat', 'snack', 'coffee'], Icons.restaurant_rounded),
    (['transport', 'travel', 'fuel', 'petrol', 'cab', 'uber', 'taxi', 'commute'], Icons.local_shipping_rounded),
    (['shop', 'cloth', 'fashion', 'amazon'], Icons.shopping_bag_rounded),
    (['educat', 'book', 'course', 'school', 'learn'], Icons.menu_book_rounded),
    (['health', 'medic', 'doctor', 'pharma', 'gym', 'fitness'], Icons.favorite_rounded),
    (['entertain', 'movie', 'game', 'fun', 'subscri', 'netflix'], Icons.movie_rounded),
    (['gift', 'donat', 'charity'], Icons.card_giftcard_rounded),
    (['phone', 'mobile', 'internet', 'recharge'], Icons.phone_iphone_rounded),
    (['invest', 'saving', 'insur'], Icons.savings_rounded),
  ];

  static IconData iconFor(String? categoryName) {
    final name = categoryName?.toLowerCase();
    if (name == null) return fallbackIcon;
    for (final (keywords, icon) in _keywordIcons) {
      if (keywords.any(name.contains)) return icon;
    }
    return fallbackIcon;
  }

  static Color colorAt(int index) => AppColors.chartPalette[index % AppColors.chartPalette.length];
}
