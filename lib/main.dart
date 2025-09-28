import 'package:flutter/material.dart';
import 'dart:async';
import 'screens/upload_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AllerScanApp());
}

class AllerScanApp extends StatelessWidget {
  const AllerScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AllerScan',
      theme: ThemeData(
        primaryColor: Colors.teal.shade600,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade600,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
        textTheme: TextTheme(
          bodyMedium: const TextStyle(color: Colors.black87, fontSize: 16),
          titleLarge: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold),
        ),
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/upload': (context) => const UploadScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'AllerScan',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.teal),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.teal.shade600),
          ],
        ),
      ),
    );
  }
}