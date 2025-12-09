import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._(); // not meant to be instantiated

  /// Base color scheme for the app.
  /// Change [seedColor] to adjust the overall look.
  static final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6750A4), // change to your brand color if you like
    brightness: Brightness.light,
  );

  static ThemeData get lightTheme {
    final base = ThemeData(
      colorScheme: _colorScheme,
      useMaterial3: true,
    );

    return base.copyWith(
      // Global scaffold background
      scaffoldBackgroundColor: _colorScheme.surface,

      // App bar styling
      appBarTheme: AppBarTheme(
        backgroundColor: _colorScheme.primary,
        foregroundColor: _colorScheme.onPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: _colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards (EventCard, list items, etc.)
      cardTheme: CardThemeData(
        color: _colorScheme.surface,
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated buttons (primary actions)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _colorScheme.primary,
          foregroundColor: _colorScheme.onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Outlined buttons (secondary actions)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _colorScheme.primary,
          side: BorderSide(color: _colorScheme.outline),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text buttons (links, subtle actions)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),

      // Text fields (login/register/profile/forms)
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _colorScheme.primary, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: _colorScheme.primary),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),

      // Chips (category filter, interests, etc.)
      chipTheme: base.chipTheme.copyWith(
        selectedColor: _colorScheme.primaryContainer,
        secondarySelectedColor: _colorScheme.primaryContainer,
        labelStyle: TextStyle(color: _colorScheme.onPrimaryContainer),
        // avoid deprecated surfaceVariant; use a modern container color
        backgroundColor: _colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      // Snackbars (feedback messages)
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: _colorScheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // FAB styling
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _colorScheme.primary,
        foregroundColor: _colorScheme.onPrimary,
      ),

      // Typography tweaks
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}