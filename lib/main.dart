import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'screens/upload_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'services/profile_service.dart';
import 'services/language_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final provider = LanguageProvider();
        provider.loadSavedLanguage();
        return provider;
      },
      child: const AllerScanApp(),
    ),
  );
}

class AllerScanApp extends StatelessWidget {
  const AllerScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final strings = languageProvider.strings;

    return MaterialApp(
      title: strings['appTitle'] ?? 'AllerScan',
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
    try {
      final profile = await _profileService.loadProfile();
      if (profile != null && profile.language.isNotEmpty && mounted) {
        await context.read<LanguageProvider>().changeLanguage(profile.language);
      }
    } catch (_) {}
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
    final strings = context.watch<LanguageProvider>().strings;
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
            Text(
              strings['initialLoadingText'] ?? 'AllerScan',
              style: const TextStyle(
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
