import 'package:flutter/material.dart';

import 'design.dart';

abstract final class RainbowTheme {
  static ThemeData get light {
    const ColorScheme scheme = ColorScheme.light(
      primary: RainbowDesign.accent,
      onPrimary: Colors.white,
      secondary: RainbowDesign.sage,
      onSecondary: RainbowDesign.text,
      surface: Colors.transparent,
      onSurface: RainbowDesign.text,
      error: RainbowDesign.danger,
    );
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: RainbowDesign.lineWarm.withAlpha(110)),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      fontFamilyFallback: const <String>[
        'PingFang SC',
        'Noto Sans CJK SC',
        'Microsoft YaHei',
      ],
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -.25,
          color: RainbowDesign.text,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
          color: RainbowDesign.text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: RainbowDesign.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.55,
          color: RainbowDesign.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: RainbowDesign.text,
        ),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withAlpha(174),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: RainbowDesign.accent, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: RainbowDesign.danger, width: 1.2),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: RainbowDesign.danger, width: 1.5),
        ),
        labelStyle: const TextStyle(color: RainbowDesign.muted),
        hintStyle: const TextStyle(color: Color(0xFFAAA69E)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: RainbowDesign.text.withAlpha(232),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: RainbowDesign.accent,
        thumbColor: RainbowDesign.accent,
        overlayColor: RainbowDesign.accent.withAlpha(28),
        inactiveTrackColor: RainbowDesign.accentSoft,
        trackHeight: 5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          return states.contains(WidgetState.selected) ? Colors.white : null;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          return states.contains(WidgetState.selected) ? RainbowDesign.accent : null;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFDFBF8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RainbowDesign.text,
          backgroundColor: Colors.white.withAlpha(105),
          side: BorderSide(color: Colors.white.withAlpha(150)),
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: RainbowDesign.accentDeep,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}
