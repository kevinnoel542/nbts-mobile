import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFC62828),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFEBEE),
    onPrimaryContainer: Color(0xFF7F1010),
    secondary: Color(0xFF111111),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEFEFF1),
    onSecondaryContainer: Color(0xFF111111),
    tertiary: Color(0xFF16A34A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD1FADF),
    onTertiaryContainer: Color(0xFF14532D),
    error: Color(0xFFC62828),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFEBEE),
    onErrorContainer: Color(0xFF7F1010),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0A0A0A),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFAFAFB),
    surfaceContainer: Color(0xFFF5F5F7),
    surfaceContainerHigh: Color(0xFFEFEFF1),
    surfaceContainerHighest: Color(0xFFE7E7EA),
    onSurfaceVariant: Color(0xFF6B7280),
    outline: Color(0xFFD1D5DB),
    outlineVariant: Color(0xFFE5E7EB),
    inverseSurface: Color(0xFF0A0A0A),
    onInverseSurface: Color(0xFFF5F5F7),
    inversePrimary: Color(0xFFEF5350),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFEF5350),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF3A0606),
    onPrimaryContainer: Color(0xFFFFCDD2),
    secondary: Color(0xFFF5F5F7),
    onSecondary: Color(0xFF0A0A0A),
    secondaryContainer: Color(0xFF1A1A1A),
    onSecondaryContainer: Color(0xFFF5F5F7),
    tertiary: Color(0xFF4ADE80),
    onTertiary: Color(0xFF062E16),
    tertiaryContainer: Color(0xFF0B3A1F),
    onTertiaryContainer: Color(0xFFBBF7D0),
    error: Color(0xFFEF5350),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF3A0606),
    onErrorContainer: Color(0xFFFFCDD2),
    surface: Color(0xFF050506),
    onSurface: Color(0xFFF5F5F7),
    surfaceContainerLowest: Color(0xFF050506),
    surfaceContainerLow: Color(0xFF0B0B0D),
    surfaceContainer: Color(0xFF111113),
    surfaceContainerHigh: Color(0xFF1A1A1D),
    surfaceContainerHighest: Color(0xFF242428),
    onSurfaceVariant: Color(0xFF9CA3AF),
    outline: Color(0xFF2A2A2A),
    outlineVariant: Color(0xFF242428),
    inverseSurface: Color(0xFFF5F5F7),
    onInverseSurface: Color(0xFF0A0A0A),
    inversePrimary: Color(0xFFC62828),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static ThemeData get lightTheme => _build(_lightScheme);
  static ThemeData get darkTheme => _build(_darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: scheme.outline),
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.10),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.primary, size: 24);
          }
          return IconThemeData(color: scheme.onSurfaceVariant, size: 24);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
