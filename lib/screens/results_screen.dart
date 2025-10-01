import 'dart:io';
import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  final String extractedIngredientsText;
  final List<String> hardAllergens;
  final List<String> softAllergens;
  final File? imageFile;

  const ResultsScreen({
    super.key,
    required this.extractedIngredientsText,
    required this.hardAllergens,
    required this.softAllergens,
    this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(imageFile!, height: 220, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Ingredients Detected:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 8),
            Text(extractedIngredientsText, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Allergens',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            const SizedBox(height: 10),
            const Text('Contains:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(hardAllergens.isNotEmpty ? hardAllergens.join(', ') : 'None'),
            const SizedBox(height: 12),
            const Text('May contain / Detected in ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(softAllergens.isNotEmpty ? softAllergens.join(', ') : 'None'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Done'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}