import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart'; // Pastikan file ini ada
import 'theme/theme_provider.dart';

void main() async {
  // Wajib ada karena kita pakai SharedPreferences sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // (Kode Notifikasi saya hapus di sini)

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const RetailApp(),
    ),
  );
}

class RetailApp extends StatelessWidget {
  const RetailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Retail Superstore',
          debugShowCheckedModeBanner: false,

          // --- LOGIKA TEMA ---
          themeMode: themeProvider.themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          // -------------------

          // CEK STATUS LOGIN DULU
          home: const AuthCheck(),
        );
      },
    );
  }
}

// --- CLASS UNTUK CEK LOGIN ---
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // Kasih jeda dikit biar berasa "Loading App" (Splash Screen sederhana)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        // Cek apakah user pernah login sebelumnya
        _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Kalau status masih null (lagi loading cek HP), tampilkan Logo Loading
    if (_isLoggedIn == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.storefront, size: 80, color: Colors.blueAccent),
              SizedBox(height: 20),
              CircularProgressIndicator(), // Loading muter-muter
            ],
          ),
        ),
      );
    }

    // 2. Kalau sudah selesai cek:
    // Sudah Login? -> Masuk Dashboard
    // Belum Login? -> Masuk Login Screen
    return _isLoggedIn! ? const DashboardScreen() : const LoginScreen();
  }
}
