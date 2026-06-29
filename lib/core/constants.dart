import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF0D47A1);
  static const Color accentBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFBBDEFB);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
}

class AppStrings {
  static const String appName = "مغسلة Moka";
  static const String adminDefaultUsername = "admin";
  static const String adminDefaultPassword = "admin123";
}

class DateTimeUtils {
  static DateTime getBusinessDayStart([DateTime? time]) {
    final t = time ?? DateTime.now();
    if (t.hour < 3) {
      return DateTime(t.year, t.month, t.day, 3, 0).subtract(const Duration(days: 1));
    } else {
      return DateTime(t.year, t.month, t.day, 3, 0);
    }
  }
}

