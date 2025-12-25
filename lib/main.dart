import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'theme/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();

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

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.storefront, size: 80, color: Colors.blueAccent),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return _isLoggedIn! ? const DashboardScreen() : const LoginScreen();
  }
}
