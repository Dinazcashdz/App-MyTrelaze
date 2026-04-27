import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Palette officielle trelaze.fr ─────────────────────────────────────────
  static const Color primary    = Color(0xFF406868); // teal foncé (header/nav)
  static const Color green      = Color(0xFF7AB86A); // vert sauge saturé (boutons actifs)
  static const Color greenLight = Color(0xFFAAD39C); // vert sauge clair (badges)
  static const Color accent     = Color(0xFFD13800); // rust/orange (CTA, alertes)
  static const Color background = Color(0xFFF0F5EE); // fond légèrement vert
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color textMain   = Color(0xFF0A2729); // quasi-noir teal
  static const Color textSub    = Color(0xFF5A7070); // gris teal

  // ── Thème clair ────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: green,
      tertiary: accent,
      surface: surface,
    ),
    scaffoldBackgroundColor: background,

    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFD4E8D4)),
      ),
      shadowColor: Colors.black12,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primary,
      unselectedItemColor: Color(0xFF8AABAB),
      backgroundColor: surface,
      elevation: 12,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      indicatorColor: primary.withValues(alpha: 0.13),
      elevation: 10,
      height: 70,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primary);
        }
        return const TextStyle(fontSize: 11, color: textSub);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary, size: 24);
        }
        return const IconThemeData(color: textSub, size: 22);
      }),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFE8F2E4),
      labelStyle: const TextStyle(color: primary, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4E8D4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4E8D4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0EDE0),
      thickness: 1,
    ),

    textTheme: GoogleFonts.interTextTheme().copyWith(
      headlineLarge: GoogleFonts.inter(color: textMain, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.inter(color: textMain, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: GoogleFonts.inter(color: textMain, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.inter(color: textMain, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(color: textMain),
      bodyMedium: GoogleFonts.inter(color: textMain),
      bodySmall: GoogleFonts.inter(color: textSub),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  // ── Thème sombre ───────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: greenLight,
      secondary: green,
      tertiary: accent,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0D1F1F),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A2729),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF122020),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E3A3A)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: greenLight,
      unselectedItemColor: Color(0xFF4A6A6A),
      backgroundColor: Color(0xFF0A2729),
      elevation: 12,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0A2729),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black54,
      indicatorColor: greenLight.withValues(alpha: 0.22),
      elevation: 10,
      height: 70,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: greenLight);
        }
        return const TextStyle(fontSize: 11, color: Color(0xFF4A6A6A));
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: greenLight, size: 24);
        }
        return const IconThemeData(color: Color(0xFF4A6A6A), size: 22);
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
    ),
  );
}
