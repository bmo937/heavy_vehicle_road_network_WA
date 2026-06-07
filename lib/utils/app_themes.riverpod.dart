import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_themes.riverpod.g.dart';

class AppThemes {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.grey[900],
    fontFamily: GoogleFonts.overpass().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      titleTextStyle: TextStyle(
        color: Colors.teal.shade50,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: primaryColor),
    ),
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: Colors.tealAccent,
      error: Colors.black,
      errorContainer: const Color(0xFFbe121e),
      onError: Colors.white,
      onErrorContainer: Colors.white,
    ),
    dividerTheme: DividerThemeData(
      indent: 10,
      endIndent: 10,
      thickness: 2,
      color: primaryColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.teal.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      selectedIconTheme: IconThemeData(color: Colors.black),
      unselectedIconTheme: IconThemeData(color: primaryColor),
      selectedLabelTextStyle: TextStyle(color: Colors.teal.shade50),
      unselectedLabelTextStyle: TextStyle(color: primaryColor),
      backgroundColor: Colors.black,
      useIndicator: true,
      indicatorColor: primaryColor,
    ),
    navigationBarTheme: NavigationBarThemeData(
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: Colors.black);
        }
        return IconThemeData(color: primaryColor);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(color: primaryColor);
        }
        return TextStyle(color: primaryColor);
      }),
      backgroundColor: Colors.black,
      indicatorColor: primaryColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    ),
    textTheme: TextTheme(
      titleMedium: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.teal.shade50, fontSize: 18, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
      bodySmall: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold),
    ),
    snackBarTheme: SnackBarThemeData(
      elevation: 20,
      backgroundColor: primaryColor,
      contentTextStyle: TextStyle(fontSize: 16, color: Colors.black),
      actionTextColor: Colors.tealAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.grey[900],
      modalBackgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: GoogleFonts.overpass().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      titleTextStyle: TextStyle(
        color: Colors.teal.shade50,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: primaryColor),
    ),
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: Colors.tealAccent,
      error: Colors.black,
      errorContainer: const Color(0xFFbe121e),
      onError: Colors.white,
      onErrorContainer: Colors.black,
    ),
    dividerTheme: DividerThemeData(
      indent: 10,
      endIndent: 10,
      thickness: 2,
      color: primaryColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.teal.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      selectedIconTheme: IconThemeData(color: Colors.teal.shade50),
      unselectedIconTheme: IconThemeData(color: primaryColor),
      selectedLabelTextStyle: TextStyle(color: primaryColor),
      unselectedLabelTextStyle: TextStyle(color: primaryColor),
      backgroundColor: Colors.white,
      useIndicator: true,
      indicatorColor: primaryColor,
    ),
    navigationBarTheme: NavigationBarThemeData(
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: Colors.teal.shade50);
        }
        return IconThemeData(color: primaryColor);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: primaryColor);
        }
        return TextStyle(color: primaryColor);
      }),
      backgroundColor: Colors.white,
      indicatorColor: primaryColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    ),
    textTheme: TextTheme(
      titleMedium: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
      bodySmall: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
    ),
    snackBarTheme: SnackBarThemeData(
      elevation: 20,
      backgroundColor: primaryColor,
      contentTextStyle: TextStyle(fontSize: 16, color: Colors.white),
      actionTextColor: const Color(0xFF64FFDA),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: primaryColor.withValues(alpha: 0.2),
    ),
  );

  static const Color primaryColor = Color(0xFF2AA198);
  static Color get oppositeColor {
    double r = 255 - primaryColor.r;
    double g = 255 - primaryColor.g;
    double b = 255 - primaryColor.b;
    return Color.from(red: r, green: g, blue: b, alpha: 1);
  }
}

@riverpod
Color primaryColor(Ref ref) {
  return const Color(0xFF2AA198);
}

@riverpod
Color oppositeColor(Ref ref) {
  Color primaryColor = ref.read(primaryColorProvider);

  double r = 255 - primaryColor.r;
  double g = 255 - primaryColor.g;
  double b = 255 - primaryColor.b;
  return Color.from(red: r, green: g, blue: b, alpha: 1);
}
