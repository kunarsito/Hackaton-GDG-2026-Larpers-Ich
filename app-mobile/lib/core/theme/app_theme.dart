import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de Colores PCB Retro-Tech / Motherboard
  static const Color solderMask = Color(0xFF0B0F0D); // Fondo principal negro mate
  static const Color darkSilicon = Color(0xFF131A16); // Superficie tarjetas/chips
  static const Color darkSiliconDeep = Color(0xFF070A08); // Superficie código/terminal
  static const Color circuitTrace = Color(0xFF1F3A2B); // Bordes pistas de circuito
  static const Color phosphorGreen = Color(0xFF00E676); // Acento primario traza verde fósforo
  static const Color phosphorGreenGlow = Color(0x3300E676); // Resplandor verde fósforo
  static const Color solderGold = Color(0xFFEAB308); // Pines soldadura dorados
  static const Color solderGoldAlt = Color(0xFFD4AF37); // Dorado alternativo
  static const Color boneWhite = Color(0xFFE2E8F0); // Texto principal blanco hueso
  static const Color greenishGray = Color(0xFF8FA89B); // Metadatos y subtítulos
  static const Color alertRed = Color(0xFFFF5252); // Alertas y errores

  static const String monoFont = 'monospace';

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: solderMask,
      canvasColor: solderMask,
      primaryColor: phosphorGreen,
      colorScheme: const ColorScheme.dark(
        primary: phosphorGreen,
        secondary: solderGold,
        surface: darkSilicon,
        error: alertRed,
        onPrimary: solderMask,
        onSecondary: solderMask,
        onSurface: boneWhite,
        onError: boneWhite,
      ),
      fontFamily: monoFont,
      cardTheme: CardThemeData(
        color: darkSilicon,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: circuitTrace, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: solderMask,
        foregroundColor: boneWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: monoFont,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: phosphorGreen,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: phosphorGreen),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSilicon,
        indicatorColor: circuitTrace,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: phosphorGreen,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: monoFont,
            );
          }
          return const TextStyle(
            color: greenishGray,
            fontSize: 11,
            fontFamily: monoFont,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: phosphorGreen);
          }
          return const IconThemeData(color: greenishGray);
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: darkSilicon,
        indicatorColor: circuitTrace,
        selectedIconTheme: IconThemeData(color: phosphorGreen),
        unselectedIconTheme: IconThemeData(color: greenishGray),
        selectedLabelTextStyle: TextStyle(
          color: phosphorGreen,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: monoFont,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: greenishGray,
          fontSize: 12,
          fontFamily: monoFont,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: circuitTrace,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSilicon,
        side: const BorderSide(color: circuitTrace),
        labelStyle: const TextStyle(
          color: boneWhite,
          fontSize: 11,
          fontFamily: monoFont,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: phosphorGreen,
          foregroundColor: solderMask,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontFamily: monoFont,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: phosphorGreen,
          side: const BorderSide(color: circuitTrace, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontFamily: monoFont,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // Estilos de texto reutilizables
  static const TextStyle codeTextStyle = TextStyle(
    fontFamily: monoFont,
    color: boneWhite,
    fontSize: 13,
    height: 1.45,
  );

  static const TextStyle chipLabelStyle = TextStyle(
    fontFamily: monoFont,
    color: solderGold,
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
}
