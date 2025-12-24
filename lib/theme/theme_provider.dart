import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// ================= TEMA TERANG (Light) =================
final lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,

  // Warna Utama
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blueAccent,
    brightness: Brightness.light,
    surface: const Color(0xFFF5F7FA), // Background abu muda
  ),

  scaffoldBackgroundColor: const Color(0xFFF5F7FA),

  // AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    elevation: 0,
  ),

  // Font Global
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),

  // Input Form
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  ),
);

// ================= TEMA GELAP (Dark) =================
final darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,

  // Warna Utama
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blueAccent,
    brightness: Brightness.dark,
    surface: const Color(0xFF121212), // Hitam
  ),

  scaffoldBackgroundColor: const Color(0xFF121212),

  // AppBar Gelap
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    elevation: 0,
  ),

  // Font Global
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),

  // Input Form Gelap
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2C2C2C),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    hintStyle: const TextStyle(color: Colors.white38),
  ),
);
