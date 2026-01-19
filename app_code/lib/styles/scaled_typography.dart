import 'package:flutter/material.dart';

/// Generates a scaled TextTheme based on a multiplier
/// Base sizes follow Material 3 guidelines
class ScaledTypography {
/// --- Display Styles ---
  /// Largest text on the screen, used for hero sections and branding.
  static const _displayLarge = 57.0;
  static const _displayMedium = 45.0;
  static const _displaySmall = 36.0;
  
  /// --- Headline Styles ---
  /// High-emphasis text for primary page headings and section markers.
  static const _headlineLarge = 32.0;
  static const _headlineMedium = 28.0;
  static const _headlineSmall = 24.0;
  
  /// --- Title Styles ---
  /// Medium-emphasis text used for card titles, list items, and subheaders.
  static const _titleLarge = 22.0;
  static const _titleMedium = 16.0;
  static const _titleSmall = 14.0;
  
  /// --- Body Styles ---
  /// Standard text for reading, used for descriptions and long paragraphs.
  static const _bodyLarge = 16.0;
  static const _bodyMedium = 14.0;
  static const _bodySmall = 12.0;
  
  /// --- Label Styles ---
  /// Functional text for components like buttons, chips, and small captions.
  static const _labelLarge = 14.0;
  static const _labelMedium = 12.0;
  static const _labelSmall = 11.0;

  /// Generate a TextTheme scaled by the given multiplier
  /// multiplier: 1.0 = base size, 0.8 = 80%, 1.4 = 140%
  static TextTheme generateScaledTextTheme({
    required double fontSizeMultiplier,
    required ColorScheme colorScheme,
  }) {
    return TextTheme(
      /// Display styles - largest, used for important headlines
      displayLarge: TextStyle(
        fontSize: _displayLarge * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: _displayMedium * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        color: colorScheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: _displaySmall * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.0,
        color: colorScheme.onSurface,
      ),

      /// Headline styles - for major sections
      headlineLarge: TextStyle(
        fontSize: _headlineLarge * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: _headlineMedium * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: _headlineSmall * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.0,
        color: colorScheme.onSurface,
      ),

      /// Title styles - for section headings
      titleLarge: TextStyle(
        fontSize: _titleLarge * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: _titleMedium * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: _titleSmall * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),

      /// Body styles - main content text
      bodyLarge: TextStyle(
        fontSize: _bodyLarge * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: _bodyMedium * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: _bodySmall * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurface,
      ),

      /// Label styles - buttons, chips, etc.
      labelLarge: TextStyle(
        fontSize: _labelLarge * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: _labelMedium * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: _labelSmall * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
    );
  }
}
