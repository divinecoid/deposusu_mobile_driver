import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF3F51B5); // Deep Indigo
  static const Color primaryLight = Color(0xFF757DE8);
  static const Color primaryDark = Color(0xFF002984);
  
  static const Color secondary = Color(0xFFFFC107); // Vibrant Amber
  static const Color secondaryLight = Color(0xFFFFE082);
  
  // Background Colors
  static const Color bgDark = Color(0xFF0F172A); // Premium Slate Dark
  static const Color cardDark = Color(0xFF1E293B); // Lighter Slate Card
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;

  // Text Colors
  static const Color textDark = Color(0xFFF1F5F9);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFF0F172A);
  static const Color textMutedLight = Color(0xFF64748B);

  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber Warning
  static const Color danger = Color(0xFFEF4444); // Rose Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [secondary, Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
