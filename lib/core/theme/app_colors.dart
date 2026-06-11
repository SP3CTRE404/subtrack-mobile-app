import 'package:flutter/material.dart';

class AppColors {
  // Vibrant, futuristic Neon Teal/Mint (from the cool image)
  static const Color cobaltBlue = Color.fromARGB(255, 17, 136, 227);

  // Dark Mode Colors
  static const Color trueBlack = Color.fromARGB(255, 17, 17, 17);
  static const Color darkSurface = Color(0xFF16171B); // Slightly elevated premium dark grey

  // Light Mode Colors
  static const Color pureWhite = Color.fromARGB(255, 255, 255, 255); // True white for max contrast
  static const Color lightSurface = Color.fromARGB(255, 244, 246, 248); // Crisp, cool-toned very light grey

  // Neon Red for destructive actions
  static const Color neonRed = Color(0xFFFF3131);

  // ── Pre-computed semi-transparent colors (Fix #4) ──
  // Avoids calling .withValues(alpha: ...) inside build() on every frame.
  
  /// Cobalt Blue at various opacities — use these instead of .withValues() in build()
  static final Color cobaltBlue10 = cobaltBlue.withValues(alpha: 0.1);
  static final Color cobaltBlue15 = cobaltBlue.withValues(alpha: 0.15);
  static final Color cobaltBlue20 = cobaltBlue.withValues(alpha: 0.2);
  static final Color cobaltBlue30 = cobaltBlue.withValues(alpha: 0.3);
  static final Color cobaltBlue40 = cobaltBlue.withValues(alpha: 0.4);
  static final Color cobaltBlue80 = cobaltBlue.withValues(alpha: 0.8);
  static final Color cobaltBlue90 = cobaltBlue.withValues(alpha: 0.9);

  /// Common surface overlay alphas
  static final Color black04 = Colors.black.withValues(alpha: 0.04);
  static final Color black10 = Colors.black.withValues(alpha: 0.1);
  static final Color black15 = Colors.black.withValues(alpha: 0.15);
  static final Color black20 = Colors.black.withValues(alpha: 0.2);
  static final Color black40 = Colors.black.withValues(alpha: 0.4);

  static final Color white06 = Colors.white.withValues(alpha: 0.06);
  static final Color white12 = Colors.white.withValues(alpha: 0.12);
  static final Color white15 = Colors.white.withValues(alpha: 0.15);
  static final Color white40 = Colors.white.withValues(alpha: 0.4);
  static final Color white60 = Colors.white.withValues(alpha: 0.6);

  /// Common onSurface overlays (theme-aware — use in dark/light respectively)
  static final Color onSurfaceLight05 = Colors.black.withValues(alpha: 0.05);
  static final Color onSurfaceLight10 = Colors.black.withValues(alpha: 0.1);
  static final Color onSurfaceLight50 = Colors.black.withValues(alpha: 0.5);
  static final Color onSurfaceLight60 = Colors.black.withValues(alpha: 0.6);

  static final Color onSurfaceDark05 = Colors.white.withValues(alpha: 0.05);
  static final Color onSurfaceDark20 = Colors.white.withValues(alpha: 0.2);
  static final Color onSurfaceDark50 = Colors.white.withValues(alpha: 0.5);
  static final Color onSurfaceDark60 = Colors.white.withValues(alpha: 0.6);
}
