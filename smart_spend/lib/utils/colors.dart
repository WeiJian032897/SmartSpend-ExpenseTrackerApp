import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF87CEEB);
  static const Color darkBlue = Color(0xFF2E5BBA);
  static const Color green = Color(0xFF4CAF50);
  static const Color red = Color(0xFFF44336);
  static const Color orange = Color(0xFFFF9800);
  static const Color purple = Color(0xFF9C27B0);
  static const Color yellow = Color(0xFFFFC107);
  static const Color teal = Color(0xFF009688);
  static const Color pink = Color(0xFFE91E63);
  static const Color grey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF424242);

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightBlue, primaryBlue],
  );
}