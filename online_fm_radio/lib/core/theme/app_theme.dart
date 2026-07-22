import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  static const Color secondaryColor = Color(0xFFEC4899);
  static const Color secondaryLight = Color(0xFFF472B6);
  static const Color secondaryDark = Color(0xFFDB2777);

  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE5E7EB);

  static const Color backgroundColorDark = Color(0xFF0F172A);
  static const Color surfaceColorDark = Color(0xFF1E293B);
  static const Color cardColorDark = Color(0xFF1E293B);
  static const Color dividerColorDark = Color(0xFF334155);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFD1D5DB);
  static const Color textTertiaryDark = Color(0xFF9CA3AF);

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusExtraLarge = 24.0;

  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primaryLight.withOpacity(0.2),
        onPrimaryContainer: primaryDark,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        secondaryContainer: secondaryLight.withOpacity(0.2),
        onSecondaryContainer: secondaryDark,
        background: backgroundColor,
        onBackground: textPrimary,
        surface: surfaceColor,
        onSurface: textPrimary,
        surfaceVariant: Colors.grey[100]!,
        onSurfaceVariant: textSecondary,
        error: Colors.red[600]!,
        onError: Colors.white,
        outline: dividerColor,
      ),
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      textTheme: _textTheme(Brightness.light),
      appBarTheme: _appBarTheme(Brightness.light),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(Brightness.light),
      elevatedButtonTheme: _elevatedButtonTheme(),
      filledButtonTheme: _filledButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      cardTheme: _cardTheme(),
      inputDecorationTheme: _inputDecorationTheme(Brightness.light),
      iconTheme: _iconTheme(Brightness.light),
      floatingActionButtonTheme: _floatingActionButtonTheme(),
      tabBarTheme: _tabBarTheme(Brightness.light),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryLight,
        onPrimary: backgroundColorDark,
        primaryContainer: primaryDark.withOpacity(0.3),
        onPrimaryContainer: primaryLight,
        secondary: secondaryLight,
        onSecondary: backgroundColorDark,
        secondaryContainer: secondaryDark.withOpacity(0.3),
        onSecondaryContainer: secondaryLight,
        background: backgroundColorDark,
        onBackground: textPrimaryDark,
        surface: surfaceColorDark,
        onSurface: textPrimaryDark,
        surfaceVariant: Colors.grey[800]!,
        onSurfaceVariant: textSecondaryDark,
        error: Colors.red[400]!,
        onError: Colors.white,
        outline: dividerColorDark,
      ),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColorDark,
      cardColor: cardColorDark,
      dividerColor: dividerColorDark,
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: _appBarTheme(Brightness.dark),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(Brightness.dark),
      elevatedButtonTheme: _elevatedButtonTheme(),
      filledButtonTheme: _filledButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      cardTheme: _cardTheme(),
      inputDecorationTheme: _inputDecorationTheme(Brightness.dark),
      iconTheme: _iconTheme(Brightness.dark),
      floatingActionButtonTheme: _floatingActionButtonTheme(),
      tabBarTheme: _tabBarTheme(Brightness.dark),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final primaryColor = brightness == Brightness.light ? textPrimary : textPrimaryDark;
    final secondaryColor = brightness == Brightness.light ? textSecondary : textSecondaryDark;
    final tertiaryColor = brightness == Brightness.light ? textTertiary : textTertiaryDark;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57.0,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontSize: 45.0,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 36.0,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleLarge: TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: 0.1,
      ),
      titleSmall: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        color: primaryColor,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        color: tertiaryColor,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.w500,
        color: tertiaryColor,
        letterSpacing: 0.5,
      ),
    );
  }

  static AppBarTheme _appBarTheme(Brightness brightness) {
    final bgColor = brightness == Brightness.light ? surfaceColor : surfaceColorDark;
    final textColor = brightness == Brightness.light ? textPrimary : textPrimaryDark;

    return AppBarTheme(
      backgroundColor: bgColor,
      foregroundColor: textColor,
      elevation: elevationSmall,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      iconTheme: IconThemeData(color: textColor),
    );
  }

  static BottomNavigationBarThemeData _bottomNavigationBarTheme(Brightness brightness) {
    final bgColor = brightness == Brightness.light ? surfaceColor : surfaceColorDark;
    final selectedColor = primaryColor;
    final unselectedColor = brightness == Brightness.light ? textTertiary : textTertiaryDark;

    return BottomNavigationBarThemeData(
      backgroundColor: bgColor,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      selectedLabelStyle: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
      elevation: elevationMedium,
      type: BottomNavigationBarType.fixed,
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        elevation: elevationSmall,
        textStyle: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme() {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        textStyle: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 2.0),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        textStyle: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        textStyle: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static CardTheme _cardTheme() {
    return CardTheme(
      elevation: elevationSmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusLarge),
      ),
      margin: const EdgeInsets.all(0.0),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(Brightness brightness) {
    final borderColor = brightness == Brightness.light ? dividerColor : dividerColorDark;
    final focusColor = primaryColor;
    final bgColor = brightness == Brightness.light ? surfaceColor : surfaceColorDark;
    final hintColor = brightness == Brightness.light ? textTertiary : textTertiaryDark;

    return InputDecorationTheme(
      filled: true,
      fillColor: bgColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: BorderSide(color: borderColor, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: BorderSide(color: borderColor, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: BorderSide(color: focusColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      hintStyle: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        color: hintColor,
      ),
      labelStyle: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: brightness == Brightness.light ? textSecondary : textSecondaryDark,
      ),
      errorStyle: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        color: Colors.red,
      ),
    );
  }

  static IconThemeData _iconTheme(Brightness brightness) {
    return IconThemeData(
      color: brightness == Brightness.light ? textPrimary : textPrimaryDark,
      size: 24.0,
    );
  }

  static FloatingActionButtonThemeData _floatingActionButtonTheme() {
    return FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusLarge),
      ),
    );
  }

  static TabBarTheme _tabBarTheme(Brightness brightness) {
    return TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: brightness == Brightness.light ? textTertiary : textTertiaryDark,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}