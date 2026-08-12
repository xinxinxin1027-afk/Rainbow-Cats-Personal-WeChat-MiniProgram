import 'package:flutter/material.dart';

/// Rainbow Cats 2026 视觉系统。
///
/// 参考了 dwell-on-something 的暖纸张色、轻描边和玻璃层级，
/// 并在 Flutter 中独立实现液态玻璃的模糊、高光与柔和阴影。
abstract final class RainbowDesign {
  static const Color background = Color(0xFFFAF8F4);
  static const Color backgroundWarm = Color(0xFFFFF1F2);
  static const Color card = Color(0xEFFFFFFF);
  static const Color panel = Color(0xBDF1EEE8);
  static const Color text = Color(0xFF2B2926);
  static const Color muted = Color(0xFF8A867C);
  static const Color line = Color(0x33FFFFFF);
  static const Color lineWarm = Color(0x24B87A84);

  static const Color accent = Color(0xFFE58CA2);
  static const Color accentDeep = Color(0xFFC95F7B);
  static const Color accentSoft = Color(0xFFFFDDE5);
  static const Color sage = Color(0xFF96B08F);
  static const Color sageSoft = Color(0xFFE7EDE2);
  static const Color amber = Color(0xFFE3A13A);
  static const Color danger = Color(0xFFC95A64);

  static const double radiusXL = 30;
  static const double radiusLarge = 24;
  static const double radiusMedium = 18;
  static const double radiusSmall = 14;

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);

  static List<BoxShadow> get softShadow => <BoxShadow>[
        BoxShadow(
          color: Colors.black.withAlpha(18),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: const Color(0xFFBE7182).withAlpha(10),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ];

  static LinearGradient get glassGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Colors.white.withAlpha(220),
          Colors.white.withAlpha(154),
        ],
      );

  static LinearGradient get accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFF09AAF),
          Color(0xFFE17D98),
        ],
      );

  static LinearGradient get warmBackdropGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFFFCFBF8),
          Color(0xFFFFF7F7),
          Color(0xFFFAF8F4),
        ],
      );
}
