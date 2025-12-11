import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart'; // Pastikan file ini sudah dibuat

void main() {
  runApp(const RetailApp());
}

class RetailApp extends StatelessWidget {
  const RetailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retail Analytics', // Judul di Tab Browser
      debugShowCheckedModeBanner: false, // Menghilangkan pita "Debug" di pojok
      // Setup Tema Global
      theme: ThemeData(
        // Warna utama aplikasi (Biru Modern)
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,

        // Wajib: Set Font Global ke Poppins
        // Jadi gak perlu set font manual di setiap Text widget
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),

      // Halaman pertama yang dibuka
      home: const DashboardScreen(),
    );
  }
}
