import 'package:flutter/material.dart';

class ColorManager {
  // Primary colors
  static const Color primary = Color(0xFF1E88E5); // Professional blue
  static const Color primaryLight = Color(
    0xFFBBDEFB,
  ); // Light blue for highlights
  static const Color primaryDark = Color(0xFF0D47A1); // Dark blue for emphasis

  // Secondary colors
  static const Color secondary = Color(0xFFFFB74D); // Warm orange
  static const Color secondaryLight = Color(0xFFFFE0B2); // Light orange
  static const Color secondaryDark = Color(
    0xFFE65100,
  ); // Dark orange for emphasis

  // Neutral colors
  static const Color dark = Color(
    0xFF263238,
  ); // Dark slate instead of pure black
  static const Color medium = Color(0xFF607D8B); // Medium gray blue
  static const Color light = Color(0xFFECEFF1); // Very light gray blue

  // Background colors
  static const Color background = Color(
    0xFFF5F7FA,
  ); // Light off-white background
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(
    0xFFE0E0E0,
  ); // Light gray for dividers

  // Text colors
  static const Color textDark = Color(0xFF263238); // Dark slate for main text
  static const Color textMedium = Color(
    0xFF607D8B,
  ); // Medium gray for secondary text
  static const Color textLight = Color(
    0xFF90A4AE,
  ); // Light gray for tertiary text

  // Success, Error, Warning colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color error = Color(0xFFE53935); // Red
  static const Color warning = Color(0xFFFFA000); // Amber
  static const Color info = Color(0xFF00ACC1); // Cyan

  // Common opacity levels
  static double opacity10 = 0.1;
  static double opacity20 = 0.2;
  static double opacity50 = 0.5;
  static double opacity70 = 0.7;
}
