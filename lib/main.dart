import 'package:flutter/material.dart';
import 'dart:async';
import 'screens/upload_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'services/profile_service.dart';

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
          iconTheme: const IconThemeData(color: Colors.white),
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
      home: const InitialScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/upload': (context) => const UploadScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// Initial screen that checks if user has completed onboarding
class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Brief splash
    final hasCompleted = await _profileService.hasCompletedOnboarding();
    
    if (!mounted) return;
    
    if (hasCompleted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety,
              size: 80,
              color: Colors.teal.shade600,
            ),
            const SizedBox(height: 20),
            const Text(
              'AllerScan',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.teal.shade600),
          ],
        ),
      ),
    );
  }
}
