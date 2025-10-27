import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ResultsScreen extends StatelessWidget {
  final String extractedIngredientsText;
  final List<String> hardAllergens;
  final List<String> softAllergens;
  final File? imageFile;
  final UserProfile? userProfile; // Add user profile parameter

  const ResultsScreen({
    super.key,
    required this.extractedIngredientsText,
    required this.hardAllergens,
    required this.softAllergens,
    this.imageFile,
    this.userProfile, // Optional user profile for filtering
  });

  final Map<String, String> _allergenLabels = const {
    'milk': '🥛 Milk',
    'eggs': '🥚 Eggs',
    'peanuts': '🥜 Peanuts',
    'tree_nuts': '🌰 Tree Nuts',
    'soy': '🫘 Soy',
    'wheat': '🌾 Wheat',
    'fish': '🐟 Fish',
    'shellfish': '🦐 Shellfish',
    'sesame': '🫘 Sesame',
    'mustard': '🌭 Mustard',
    'sulphites': '🧪 Sulphites',
  };

  @override
  Widget build(BuildContext context) {
    // Get all detected allergens (both hard and soft)
    final allDetectedAllergens = {...hardAllergens, ...softAllergens};

    // Get user's allergens from profile
    final userAllergens = userProfile?.getAllAllergens() ?? [];

    // Categorize allergens based on user's profile
    final userAllergensDetected = allDetectedAllergens.where((allergen) => userAllergens.contains(allergen)).toList();
    final userAllergensNotDetected = userAllergens.where((allergen) => !allDetectedAllergens.contains(allergen)).toList();
    final otherAllergensDetected = allDetectedAllergens.where((allergen) => !userAllergens.contains(allergen)).toList();

    // Separate hard and soft allergens for user's allergens
    final userHardAllergens = hardAllergens.where((allergen) => userAllergens.contains(allergen)).toList();
    final userSoftAllergens = softAllergens.where((allergen) => userAllergens.contains(allergen)).toList();

    // Determine alert level based on user's allergens
    final hasUserAllergens = userAllergensDetected.isNotEmpty;
    final hasCriticalAllergens = userHardAllergens.isNotEmpty;
    final bool hasAnyAllergens = hardAllergens.isNotEmpty || softAllergens.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Scan Results'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personalized alert banner based on user's allergens
            if (userProfile != null && userAllergens.isNotEmpty)
              _buildPersonalizedAlertBanner(
                hasUserAllergens: hasUserAllergens,
                hasCriticalAllergens: hasCriticalAllergens,
                userAllergensDetected: userAllergensDetected,
                userName: userProfile!.name,
              )
            else
              // Fallback to original alert banner (no user profile)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hardAllergens.isNotEmpty
                        ? [Colors.red.shade400, Colors.red.shade600]
                        : [Colors.orange.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hardAllergens.isNotEmpty ? Icons.warning : Icons.info,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hardAllergens.isNotEmpty ? 'Allergens Detected!' : 'Possible Allergens',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hardAllergens.isNotEmpty
                                ? 'This product contains allergens'
                                : 'This product may contain allergens',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scanned image
                  if (imageFile != null) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          imageFile!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // User's allergen results (if profile available and has allergens)
                  if (userProfile != null && userAllergens.isNotEmpty) ...[
                    // User's allergens that were DETECTED
                    if (userAllergensDetected.isNotEmpty) ...[
                      _buildUserAllergenSection(
                        title: '⚠️ Your Allergens Detected',
                        allergens: userAllergensDetected,
                        hardAllergens: userHardAllergens,
                        softAllergens: userSoftAllergens,
                        isCritical: hasCriticalAllergens,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // User's allergens that were NOT detected (for awareness)
                    if (userAllergensNotDetected.isNotEmpty) ...[
                      _buildUserAllergenSection(
                        title: '✅ Your Safe Allergens',
                        allergens: userAllergensNotDetected,
                        hardAllergens: [],
                        softAllergens: [],
                        isCritical: false,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],

                  // All detected allergens (original sections, but less prominent if user has profile)
                  if (hardAllergens.isNotEmpty || softAllergens.isNotEmpty) ...[
                    if (userProfile != null && userAllergens.isNotEmpty) ...[
                      const Text(
                        'All Detected Allergens',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (hardAllergens.isNotEmpty) ...[
                      _buildAllergenSection(
                        title: 'Contains',
                        icon: Icons.dangerous,
                        color: Colors.red,
                        allergens: hardAllergens,
                        description: 'These allergens are confirmed in this product',
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (softAllergens.isNotEmpty) ...[
                      _buildAllergenSection(
                        title: 'May Contain',
                        icon: Icons.warning_amber,
                        color: Colors.orange,
                        allergens: softAllergens,
                        description: 'These allergens were detected in the ingredients list',
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],

                  // Ingredients section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list_alt, color: Colors.teal.shade600, size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              'Ingredients Detected',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            extractedIngredientsText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Scan Another'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.teal.shade600, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          icon: const Icon(Icons.home),
                          label: const Text('Home'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.teal.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedAlertBanner({
    required bool hasUserAllergens,
    required bool hasCriticalAllergens,
    required List<String> userAllergensDetected,
    required String userName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasCriticalAllergens
              ? [Colors.red.shade400, Colors.red.shade600]
              : hasUserAllergens
                  ? [Colors.orange.shade400, Colors.orange.shade600]
                  : [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasCriticalAllergens
                ? Icons.warning
                : hasUserAllergens
                    ? Icons.warning_amber
                    : Icons.check_circle,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCriticalAllergens
                      ? 'Danger! Your Allergens Found'
                      : hasUserAllergens
                          ? 'Warning: Your Allergens Detected'
                          : 'Safe for You',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasCriticalAllergens
                      ? 'This product contains allergens you\'re allergic to'
                      : hasUserAllergens
                          ? 'This product contains some of your allergens'
                          : 'This product doesn\'t contain your allergens',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                if (userAllergensDetected.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Detected: ${userAllergensDetected.map((a) => _allergenLabels[a] ?? a).join(', ')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAllergenSection({
    required String title,
    required List<String> allergens,
    required List<String> hardAllergens,
    required List<String> softAllergens,
    required bool isCritical,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical ? Colors.red.shade200 : Colors.green.shade200,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isCritical ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergens.map((allergen) {
              final isHardAllergen = hardAllergens.contains(allergen);
              final isSoftAllergen = softAllergens.contains(allergen);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isHardAllergen
                      ? Colors.red.shade100
                      : isSoftAllergen
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isHardAllergen
                        ? Colors.red.shade300
                        : isSoftAllergen
                            ? Colors.orange.shade300
                            : Colors.green.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _allergenLabels[allergen] ?? allergen,
                      style: TextStyle(
                        color: isHardAllergen
                            ? Colors.red.shade700
                            : isSoftAllergen
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (isHardAllergen) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.warning, size: 14, color: Colors.red.shade700),
                    ] else if (isSoftAllergen) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.info, size: 14, color: Colors.orange.shade700),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergenSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> allergens,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha((0.3 * 255).toInt()), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergens.map((allergen) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withAlpha((0.3 * 255).toInt())),
                ),
                child: Text(
                  _allergenLabels[allergen] ?? allergen,
                  style: TextStyle(
                    color: color.withAlpha((0.9 * 255).toInt()),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}