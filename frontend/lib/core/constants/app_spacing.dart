import 'package:flutter/material.dart';

/// Chronicle Design System — Spacing (8pt grid)
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // ── Vertical gaps (SizedBox shortcuts) ──
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl);

  // ── Horizontal gaps ──
  static const SizedBox hGapXs = SizedBox(width: xs);
  static const SizedBox hGapSm = SizedBox(width: sm);
  static const SizedBox hGapMd = SizedBox(width: md);
  static const SizedBox hGapLg = SizedBox(width: lg);

  // ── Common padding ──
  static const EdgeInsets paddingAll = EdgeInsets.all(md);
  static const EdgeInsets paddingHorizontal = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(horizontal: xl, vertical: lg);

  // ── Border Radius ──
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusXxl = 32.0;
  static const double radiusPill = 999.0;

  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadiusXxl => BorderRadius.circular(radiusXxl);
  static BorderRadius get borderRadiusPill => BorderRadius.circular(radiusPill);

  // ── Revamped layout tokens ──
  /// Horizontal gutter used by the rebuilt (dashboard/expenses) screens.
  static const double gutter = 20.0;
  static const EdgeInsets paddingGutter = EdgeInsets.symmetric(horizontal: gutter);

  /// Card inner padding.
  static const double cardPadding = 20.0;
  static const EdgeInsets paddingCard = EdgeInsets.all(cardPadding);

  // ── Component sizes ──
  static const double iconButtonSize = 48.0; // Round header buttons
  static const double navItemSize = 52.0; // Floating nav circles
  static const double navBarPadding = 6.0;
  static const double iconBadgeSize = 44.0; // Round icon holders in tiles
  static const double avatarSize = 48.0;
  static const double ringSizeSm = 44.0; // Small percentage rings
  static const double ringStrokeSm = 4.0;
  static const double donutSize = 220.0;
  static const double donutStroke = 14.0;
  static const double donutSizeSm = 128.0;
  static const double donutStrokeSm = 11.0;
  static const double chartHeight = 190.0;
  static const double statCardWidth = 168.0;
  static const double insightCardWidth = 200.0;
  static const double glanceTileHeight = 116.0;
  static const double chartHeightCompact = 150.0;
  static const double progressBarHeight = 8.0;
  static const double ringSizeLg = 72.0; // Hero progress rings
  static const double ringStrokeLg = 7.0;
  static const double checkCircleSize = 26.0; // Todo check circles
  static const double accentDotSize = 8.0;
  static const double visitPhotoSize = 72.0;
}
