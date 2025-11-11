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

  // English allergen labels
  final Map<String, String> _englishAllergenLabels = const {
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
  
  // French allergen labels
  final Map<String, String> _frenchAllergenLabels = const {
    'milk': '🥛 Lait',
    'eggs': '🥚 Œufs',
    'peanuts': '🥜 Arachides',
    'tree_nuts': '🌰 Noix',
    'soy': '🫘 Soja',
    'wheat': '🌾 Blé',
    'fish': '🐟 Poisson',
    'shellfish': '🦐 Crustacés',
    'sesame': '🫘 Sésame',
    'mustard': '🌭 Moutarde',
    'sulphites': '🧪 Sulfites',
  };
  
  // Map between English and French allergen keys
  final Map<String, String> _allergenKeyMap = const {
    // English to French
    'milk': 'lait',
    'eggs': 'oeufs',
    'peanuts': 'arachides',
    'tree_nuts': 'noix',
    'soy': 'soja',
    'wheat': 'blé',
    'fish': 'poisson',
    'shellfish': 'crustacés',
    'sesame': 'sésame',
    'mustard': 'moutarde',
    'sulphites': 'sulfites',
    // French to English
    'lait': 'milk',
    'oeufs': 'eggs',
    'arachides': 'peanuts',
    'noix': 'tree_nuts',
    'soja': 'soy',
    'blé': 'wheat',
    'poisson': 'fish',
    'crustacés': 'shellfish',
    'sésame': 'sesame',
    'moutarde': 'mustard',
    'sulfites': 'sulphites',
  };
  
  // Get allergen label based on user's language
  String _getAllergenLabel(String allergenKey) {
    final isFrench = userProfile?.language == 'fr';
    final label = isFrench
        ? _frenchAllergenLabels[allergenKey]
        : _englishAllergenLabels[allergenKey];
    return label ?? allergenKey;
  }
  
  // Convert allergen key to the correct language
  String _normalizeAllergenKey(String allergenKey) {
    final isFrench = userProfile?.language == 'fr';
    
    // If we're in French mode and have an English key, convert it to French
    if (isFrench && _allergenKeyMap.containsKey(allergenKey)) {
      return _allergenKeyMap[allergenKey] ?? allergenKey;
    }
    
    // If we're in English mode and have a French key, convert it to English
    if (!isFrench && _allergenKeyMap.containsKey(allergenKey)) {
      return _allergenKeyMap[allergenKey] ?? allergenKey;
    }
    
    return allergenKey;
  }

  @override
  Widget build(BuildContext context) {
    // Debug print statement for non-detected allergens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userAllergens = userProfile?.getAllAllergens() ?? [];
      final mappedUserAllergens = userAllergens.map((allergen) => _normalizeAllergenKey(allergen)).toList();
      final allDetectedAllergens = {...hardAllergens, ...softAllergens};
      
      final userAllergensNotDetected = userAllergens.where((allergen) => 
          !allDetectedAllergens.contains(allergen) && 
          !allDetectedAllergens.contains(_normalizeAllergenKey(allergen))
      ).toList();
      
      final userHardAllergens = hardAllergens.where((allergen) => 
          mappedUserAllergens.contains(allergen) || 
          mappedUserAllergens.contains(_normalizeAllergenKey(allergen))
      ).toList();
      
      print('Post-frame mapped user allergens: $mappedUserAllergens');
      print('Post-frame detected allergens: $allDetectedAllergens');
      
      if (userAllergensNotDetected.isNotEmpty && userHardAllergens.isEmpty) {
        print('Post-build: Showing non-detected allergens: $userAllergensNotDetected');
      } else {
        print('Post-build: NOT showing non-detected allergens due to detected critical allergens');
      }
    });
    
    // Get all detected allergens (both hard and soft)
    final allDetectedAllergens = {...hardAllergens, ...softAllergens};
    print('All detected allergens: $allDetectedAllergens');

    // Get user's allergens from profile
    final userAllergens = userProfile?.getAllAllergens() ?? [];
    print('User allergens from profile: $userAllergens');

    // Map user allergens to the correct language keys for comparison
    final mappedUserAllergens = userAllergens.map((allergen) => _normalizeAllergenKey(allergen)).toList();
    
    // Categorize allergens based on user's profile
    final userAllergensDetected = allDetectedAllergens.where((allergen) => 
        mappedUserAllergens.contains(allergen) || 
        mappedUserAllergens.contains(_normalizeAllergenKey(allergen))
    ).toList();
    
    final userAllergensNotDetected = userAllergens.where((allergen) => 
        !allDetectedAllergens.contains(allergen) && 
        !allDetectedAllergens.contains(_normalizeAllergenKey(allergen))
    ).toList();
    
    final otherAllergensDetected = allDetectedAllergens.where((allergen) => 
        !mappedUserAllergens.contains(allergen) && 
        !mappedUserAllergens.contains(_normalizeAllergenKey(allergen))
    ).toList();
    
    print('User allergens DETECTED in product: $userAllergensDetected');
    print('User allergens NOT detected in product: $userAllergensNotDetected');
    print('Other allergens detected (not in user profile): $otherAllergensDetected');

    // Separate hard and soft allergens for user's allergens
    final userHardAllergens = hardAllergens.where((allergen) => 
        mappedUserAllergens.contains(allergen) || 
        mappedUserAllergens.contains(_normalizeAllergenKey(allergen))
    ).toList();
    
    final userSoftAllergens = softAllergens.where((allergen) => 
        mappedUserAllergens.contains(allergen) || 
        mappedUserAllergens.contains(_normalizeAllergenKey(allergen))
    ).toList();
    
    print('Hard allergens in product: $hardAllergens');
    print('Soft allergens in product: $softAllergens');
    print('User HARD allergens detected: $userHardAllergens');
    print('User SOFT allergens detected: $userSoftAllergens');

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
                        title: userProfile?.language == 'fr'
                            ? '⚠️ ATTENTION: Vos Allergènes Détectés!'
                            : '⚠️ Your Allergens Detected',
                        allergens: userAllergensDetected,
                        hardAllergens: userHardAllergens,
                        softAllergens: userSoftAllergens,
                        isCritical: hasCriticalAllergens,
                        description: userProfile?.language == 'fr'
                            ? 'Ces allergènes de votre profil ont été détectés dans ce produit'
                            : 'These allergens from your profile were detected in this product',
                      ),
                      const SizedBox(height: 16),
                    ],

                    // User's allergens that were NOT detected (for awareness)
                    // Only show this section if we have allergens that weren't detected AND
                    // there are no critical allergens detected (otherwise it's misleading)
                    if (userAllergensNotDetected.isNotEmpty && !hasCriticalAllergens) ...[
                      _buildUserAllergenSection(
                        title: userProfile?.language == 'fr'
                            ? '✅ Allergènes Non Détectés'
                            : '✅ Your Safe Allergens',
                        allergens: userAllergensNotDetected,
                        hardAllergens: [],
                        softAllergens: [],
                        isCritical: false,
                        description: userProfile?.language == 'fr'
                            ? 'Ces allergènes de votre profil n\'ont pas été détectés dans ce produit'
                            : 'These allergens from your profile were not detected in this product',
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],

                  // All detected allergens (original sections, but less prominent if user has profile)
                  if (hardAllergens.isNotEmpty) ...[
                    if (userProfile != null && userAllergens.isNotEmpty) ...[
                      Text(
                        userProfile?.language == 'fr'
                            ? 'Tous les Allergènes Détectés'
                            : 'All Detected Allergens',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (hardAllergens.isNotEmpty) ...[
                      _buildAllergenSection(
                        title: userProfile?.language == 'fr' ? 'Contient' : 'Contains',
                        icon: Icons.dangerous,
                        color: Colors.red,
                        allergens: hardAllergens,
                        description: userProfile?.language == 'fr'
                            ? 'Ces allergènes sont confirmés dans ce produit'
                            : 'These allergens are confirmed in this product',
                      ),
                      const SizedBox(height: 12),
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
                            Text(
                              userProfile?.language == 'fr' ? 'Ingrédients Détectés' : 'Ingredients Detected',
                              style: const TextStyle(
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
                          label: Text(userProfile?.language == 'fr' ? 'Scanner un Autre' : 'Scan Another'),
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
                          label: Text(userProfile?.language == 'fr' ? 'Accueil' : 'Home'),
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
                  userProfile?.language == 'fr'
                      ? (hasCriticalAllergens
                          ? 'DANGER! Vos Allergènes Trouvés!'
                          : hasUserAllergens
                              ? 'ATTENTION: Vos Allergènes Détectés!'
                              : 'Sûr pour Vous')
                      : (hasCriticalAllergens
                          ? 'DANGER! Your Allergens Found!'
                          : hasUserAllergens
                              ? 'WARNING: Your Allergens Detected!'
                              : 'Safe for You'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userProfile?.language == 'fr'
                      ? (hasCriticalAllergens
                          ? 'Ce produit contient des allergènes auxquels vous êtes allergique'
                          : hasUserAllergens
                              ? 'Ce produit contient certains de vos allergènes'
                              : 'Ce produit ne contient pas vos allergènes')
                      : (hasCriticalAllergens
                          ? 'This product contains allergens you\'re allergic to'
                          : hasUserAllergens
                              ? 'This product contains some of your allergens'
                              : 'This product doesn\'t contain your allergens'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                if (userAllergensDetected.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    userProfile?.language == 'fr'
                        ? 'Détecté: ${userAllergensDetected.map((a) => _getAllergenLabel(a)).join(', ')}'
                        : 'Detected: ${userAllergensDetected.map((a) => _getAllergenLabel(a)).join(', ')}',
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
    String? description,
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
          if (description != null) ...[  
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: isCritical ? Colors.red.shade600 : Colors.green.shade700,
              ),
            ),
          ],
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
                      _getAllergenLabel(allergen),
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
                  _getAllergenLabel(allergen),
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