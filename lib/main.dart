import 'package:flutter/material.dart';

void main() {
  runApp(const AllerScanApp());
}

class AllerScanApp extends StatelessWidget {
  const AllerScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AllerScan',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AllerScan')),
      body: const Center(child: Text('Welcome to AllerScan!')),
    );
  }
}