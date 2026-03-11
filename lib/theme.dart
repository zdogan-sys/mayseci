import 'package:flutter/material.dart';

// ================================================================
//  theme.dart — BrewMaster Pro
//  Dashboard ile aynı renk paleti
// ================================================================

class BmColors {
  BmColors._();
  static const bg       = Color(0xFF0D0D0D);
  static const panel    = Color(0xFF111111);
  static const border   = Color(0xFF202020);
  static const text     = Color(0xFFFFFFFF);
  static const dim      = Color(0xFF808080);
  static const amber    = Color(0xFFFF8C00);   // Mayşeleme
  static const green    = Color(0xFF4CAF50);   // Fermentasyon
  static const cyan     = Color(0xFF60B8D0);   // Süt ürünleri
  static const purple   = Color(0xFFC060E0);   // Distilasyon
  static const orange   = Color(0xFFD06040);   // Manuel
  static const red      = Color(0xFFE53935);   // Alarm
  static const darkRed  = Color(0xFF6A2010);

  static const moduleColors = [
    Colors.transparent, // 0 = home
    amber,    // 1 = mash
    green,    // 2 = ferm
    cyan,     // 3 = dairy
    purple,   // 4 = dist
    orange,   // 5 = manual
  ];

  static Color forModule(int idx) =>
      idx >= 0 && idx < moduleColors.length ? moduleColors[idx] : dim;
}

class BmTextStyles {
  BmTextStyles._();

  static const bigTemp = TextStyle(
    fontFamily: 'BebasNeue',
    fontSize: 72,
    letterSpacing: 2,
    height: 1.0,
  );

  static const medTemp = TextStyle(
    fontFamily: 'BebasNeue',
    fontSize: 36,
    letterSpacing: 2,
    height: 1.0,
  );

  static const timer = TextStyle(
    fontFamily: 'BebasNeue',
    fontSize: 48,
    letterSpacing: 4,
    height: 1.0,
  );

  static const label = TextStyle(
    fontSize: 10,
    letterSpacing: 2.5,
    color: BmColors.dim,
    fontWeight: FontWeight.w500,
  );

  static const mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    color: BmColors.dim,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: BmColors.bg,
    colorScheme: const ColorScheme.dark(
      primary:   BmColors.amber,
      secondary: BmColors.green,
      surface:   BmColors.panel,
      error:     BmColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: BmColors.panel,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'BebasNeue',
        fontSize: 20,
        letterSpacing: 3,
        color: BmColors.text,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: BmColors.panel,
      selectedItemColor: BmColors.amber,
      unselectedItemColor: BmColors.dim,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 10, letterSpacing: 1),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
    cardTheme: CardTheme(
      color: BmColors.panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: BmColors.border),
      ),
    ),
    dividerColor: BmColors.border,
    sliderTheme: SliderThemeData(
      activeTrackColor: BmColors.amber,
      thumbColor: BmColors.amber,
      inactiveTrackColor: BmColors.border,
      overlayColor: BmColors.amber.withOpacity(0.2),
      trackHeight: 4,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? BmColors.amber : BmColors.dim,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? BmColors.amber.withOpacity(0.4)
            : BmColors.border,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BmColors.amber,
        foregroundColor: BmColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(
          fontFamily: 'BebasNeue',
          fontSize: 16,
          letterSpacing: 2,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BmColors.panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: BmColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: BmColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: BmColors.amber),
      ),
      labelStyle: const TextStyle(color: BmColors.dim),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}
