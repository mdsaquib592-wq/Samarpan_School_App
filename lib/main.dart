import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🚀 Naya Import
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

// 🚀 App start hone se pehle check karenge ki purana theme kya tha
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(SamarpanApp(isDark: isDarkMode));
}

class SamarpanApp extends StatefulWidget {
  final bool isDark;
  const SamarpanApp({super.key, required this.isDark});

  // 🚀 Theme change karne ka universal function (Kahin se bhi call kar sakte hain)
  static _SamarpanAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_SamarpanAppState>();

  @override
  State<SamarpanApp> createState() => _SamarpanAppState();
}

class _SamarpanAppState extends State<SamarpanApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // 🚀 Theme update karke memory me save karna
  void changeTheme(ThemeMode themeMode) async {
    setState(() {
      _themeMode = themeMode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Samarpan Vidyalaya',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode, // 👈 Ab theme yahan se control hoga
      // ☀️ LIGHT THEME
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF059669),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),

      // 🌙 DARK THEME
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF059669),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: const Color(0xFFF8FAFC),
              displayColor: const Color(0xFFF8FAFC),
            ),
      ),

      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
