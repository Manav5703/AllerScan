import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _customAllergenController = TextEditingController();
  final ProfileService _profileService = ProfileService();

  // Available allergens based on the allergens_en.json
  final Map<String, String> _availableAllergens = {
    'milk': '🥛 Milk & Dairy',
    'eggs': '🥚 Eggs',
    'peanuts': '🥜 Peanuts',
    'tree_nuts': '🌰 Tree Nuts',
    'soy': '🫘 Soy',
    'wheat': '🌾 Wheat/Gluten',
    'fish': '🐟 Fish',
    'shellfish': '🦐 Shellfish',
    'sesame': '🫘 Sesame',
    'mustard': '🌭 Mustard',
    'sulphites': '🧪 Sulphites',
  };

  final Set<String> _selectedAllergens = {};
  final List<String> _customAllergens = [];
  String _selectedLanguage = 'en';
  String? _selectedAvatar;
  String? _avatarPhotoPath;
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();

  final List<String> _avatarOptions = ['👤', '👨', '👩', '🧑', '👦', '👧', '🧔', '👱‍♀️', '👱‍♂️'];

  @override
  void dispose() {
    _nameController.dispose();
    _customAllergenController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickProfilePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _avatarPhotoPath = image.path;
        _selectedAvatar = null; // Clear emoji selection
      });
    }
  }

  Future<void> _saveProfile() async {
    final profile = UserProfile(
      name: _nameController.text.trim(),
      allergens: _selectedAllergens.toList(),
      customAllergens: _customAllergens,
      language: _selectedLanguage,
      avatarEmoji: _selectedAvatar,
      avatarPhotoPath: _avatarPhotoPath,
    );

    final success = await _profileService.saveProfile(profile);
    
    if (!mounted) return;
    
    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save profile. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addCustomAllergen() {
    final allergen = _customAllergenController.text.trim();
    if (allergen.isNotEmpty && !_customAllergens.contains(allergen)) {
      setState(() {
        _customAllergens.add(allergen);
        _customAllergenController.clear();
      });
    }
  }

  void _removeCustomAllergen(String allergen) {
    setState(() {
      _customAllergens.remove(allergen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _buildCurrentStep(),
              ),
            ),
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildAllergenSelectionStep();
      case 2:
        return _buildPreferencesStep();
      default:
        return _buildWelcomeStep();
    }
  }

  Widget _buildWelcomeStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Icon(
              Icons.health_and_safety,
              size: 80,
              color: Colors.teal.shade600,
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Welcome to AllerScan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Your personal allergy detection assistant',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            'Choose your avatar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Custom photo option
          GestureDetector(
            onTap: _pickProfilePhoto,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _avatarPhotoPath != null ? Colors.teal.shade50 : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _avatarPhotoPath != null ? Colors.teal.shade600 : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  if (_avatarPhotoPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_avatarPhotoPath!),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add_a_photo, color: Colors.grey[600]),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _avatarPhotoPath != null ? 'Custom Photo Selected' : 'Upload Custom Photo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _avatarPhotoPath != null ? Colors.teal.shade700 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _avatarPhotoPath != null ? 'Tap to change' : 'Choose from gallery',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'OR',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose an emoji avatar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _avatarOptions.map((emoji) {
              final isSelected = _selectedAvatar == emoji && _avatarPhotoPath == null;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedAvatar = emoji;
                  _avatarPhotoPath = null; // Clear photo selection
                }),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.teal.shade100 : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.teal.shade600 : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const Text(
            'What\'s your name?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllergenSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Select Your Allergens',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose all allergens you need to avoid',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 24),
        // Standard allergens
        ..._availableAllergens.entries.map((entry) {
          final isSelected = _selectedAllergens.contains(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedAllergens.remove(entry.key);
                  } else {
                    _selectedAllergens.add(entry.key);
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.teal.shade50 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.teal.shade600 : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? Colors.teal.shade600 : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 24),
        // Custom allergens section
        const Text(
          'Add Custom Allergens',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customAllergenController,
                decoration: InputDecoration(
                  hintText: 'e.g., Corn, Celery',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                  ),
                ),
                onSubmitted: (_) => _addCustomAllergen(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addCustomAllergen,
              icon: Icon(Icons.add_circle, color: Colors.teal.shade600, size: 32),
            ),
          ],
        ),
        if (_customAllergens.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _customAllergens.map((allergen) {
              return Chip(
                label: Text(allergen),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeCustomAllergen(allergen),
                backgroundColor: Colors.orange.shade100,
                deleteIconColor: Colors.orange.shade900,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Almost Done!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Set your preferences',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Preferred Language',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildLanguageOption('en', 'English', '🇬🇧'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLanguageOption('fr', 'Français', '🇫🇷'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(),
      ],
    );
  }

  Widget _buildLanguageOption(String code, String name, String flag) {
    final isSelected = _selectedLanguage == code;
    return InkWell(
      onTap: () => setState(() => _selectedLanguage = code),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade50 : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.teal.shade600 : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_selectedAvatar != null)
                Text(_selectedAvatar!, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _nameController.text.trim(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Allergens to avoid:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedAllergens.isEmpty && _customAllergens.isEmpty)
            const Text(
              'None selected',
              style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ..._selectedAllergens.map((key) => Chip(
                      label: Text(
                        _availableAllergens[key]!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.red.shade100,
                      padding: EdgeInsets.zero,
                    )),
                ..._customAllergens.map((allergen) => Chip(
                      label: Text(allergen, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.orange.shade100,
                      padding: EdgeInsets.zero,
                    )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.teal.shade600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.teal.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == 2 ? 'Get Started' : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
