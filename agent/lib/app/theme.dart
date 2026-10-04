import 'package:flutter/material.dart';

import '../domain/hour_limits.dart';

abstract final class AppColors {
  static const primary = Color(0xFF1F4E79);
  static const background = Color(0xFFF5F6F8);
  static const surface = Colors.white;
  static const ok = Color(0xFF2E7D32);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFC62828);
  static const muted = Color(0xFF6B7280);

  static Color forUsage(UsageLevel level) => switch (level) {
        UsageLevel.normal => primary,
        UsageLevel.warning => warning,
        UsageLevel.over => danger,
      };
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.surface,
    error: AppColors.danger,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    visualDensity: VisualDensity.standard,
  );
  final text = base.textTheme;
  return base.copyWith(
    textTheme: text.copyWith(
      displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w600),
      headlineMedium: text.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: text.titleMedium?.copyWith(fontSize: 18),
      bodyLarge: text.bodyLarge?.copyWith(fontSize: 18),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 16),
      labelLarge: text.labelLarge?.copyWith(fontSize: 16),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(160, 56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: Color(0xFFE2E5EA)),
      ),
    ),
  );
}
