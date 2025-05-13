import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2C2C2E);
  static const Color accentColor = Color(0xFF666666);
  static const Color backgroundColor = Colors.black;
  static const Color surfaceColor = Color(0xFF1C1C1E);
  static const Color textColor = Colors.white;
  static const Color secondaryTextColor = Color(0xFFAAAAAA);
  static const Color dividerColor = Color(0xFF2C2C2E);
  static const Color buttonColor = Color(0xFF2C2C2E);
  static const Color selectedColor = Color(0xFF3A3A3C);
  static const Color tagColor = Color(0xFF2C2C2E);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    textTheme: GoogleFonts.openSansTextTheme(
      ThemeData.dark().textTheme.copyWith(
            headlineLarge: const TextStyle(
              color: textColor,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            bodyLarge: const TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            bodyMedium: const TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
    ),
    cardColor: Color(0xFF2C2C2E),
    chipTheme: ChipThemeData(
      backgroundColor: tagColor,
      selectedColor: selectedColor,
      labelStyle: GoogleFonts.openSans(
        color: textColor,
        fontSize: 14,
      ),
      secondaryLabelStyle: GoogleFonts.openSans(
        color: textColor,
        fontSize: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: textColor),
      titleTextStyle: GoogleFonts.openSans(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: textColor,
      unselectedItemColor: secondaryTextColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: GoogleFonts.openSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentColor),
      ),
      labelStyle: GoogleFonts.openSans(color: secondaryTextColor),
      hintStyle: GoogleFonts.openSans(color: secondaryTextColor),
    ),
    cardTheme: CardTheme(
      color: Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
    ),
  );
}
