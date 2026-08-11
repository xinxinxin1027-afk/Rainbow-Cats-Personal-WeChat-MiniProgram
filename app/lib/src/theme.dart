import 'package:flutter/material.dart';

import '../generated/original_style.dart';

abstract final class RainbowTheme {
  static ThemeData get light {
    const ColorScheme scheme = ColorScheme.light(
      primary: OriginalStyle.primary,
      secondary: OriginalStyle.primaryDark,
      surface: OriginalStyle.surface,
    );
    return ThemeData(
      useMaterial3: false,
      colorScheme: scheme,
      scaffoldBackgroundColor: OriginalStyle.background,
      fontFamilyFallback: const <String>[
        'PingFang SC',
        'Noto Sans CJK SC',
        'Microsoft YaHei',
      ],
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: OriginalStyle.text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: OriginalStyle.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: OriginalStyle.text,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OriginalStyle.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OriginalStyle.cardRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OriginalStyle.cardRadius),
          borderSide: const BorderSide(color: OriginalStyle.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OriginalStyle.cardRadius),
          borderSide: const BorderSide(
            color: OriginalStyle.primary,
            width: 1.4,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: OriginalStyle.primary,
        thumbColor: OriginalStyle.primary,
        overlayColor: OriginalStyle.primary.withAlpha(30),
        inactiveTrackColor: OriginalStyle.divider,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
