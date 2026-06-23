import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens translated from the `truckfinder App Flow` wireframe
/// (kit.jsx `:root`). The source used OKLCH; values below are the sRGB
/// equivalents. Distinct **blue** accent set the companion app apart from
/// maalgaadi's data source.
class AppColors {
  AppColors._();

  static const bg = Color(0xFFFAFBFC);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2B313A);
  static const muted = Color(0xFF79818C);
  static const line = Color(0xFFE7E9ED);

  static const accent = Color(0xFF2F63D9);
  static const accentSoft = Color(0xFFEAF0FC);
  static const accentLine = Color(0xFFB9CCF3);

  // Striped placeholder fills.
  static const ph = Color(0xFFE9EBEF);
  static const ph2 = Color(0xFFF2F3F6);

  // Availability semantics.
  static const ok = Color(0xFF2F9E6A); // empty now
  static const okBg = Color(0xFFE5F5EC);
  static const warn = Color(0xFFC9881E); // empty soon
  static const warnBg = Color(0xFFF6EDD9);
  static const bad = Color(0xFFD04B3B); // alerts / destructive
  static const badBg = Color(0xFFF8E7E3);
}

/// Typography helpers. English/Latin copy uses Noto Sans; the bilingual
/// Hindi (`hi`) sub-labels use Noto Sans Devanagari so Devanagari glyphs
/// render correctly.
class AppText {
  AppText._();

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.notoSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Devanagari sub-label (the `.hi` class in the design).
  static TextStyle deva({
    double size = 12,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.muted,
    double? height,
  }) =>
      GoogleFonts.notoSansDevanagari(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      surface: AppColors.card,
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.notoSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    splashColor: AppColors.accentSoft,
    highlightColor: AppColors.accentSoft.withValues(alpha: 0.4),
  );
}
