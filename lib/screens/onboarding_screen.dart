import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/language_provider.dart';

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

  // Allergen labels will be loaded based on selected language
  Map<String, String> _availableAllergens = {};

  final Set<String> _selectedAllergens = {};
  final List<String> _customAllergens = [];
  String _selectedLanguage = 'en';
  String? _selectedAvatar;
  int _currentStep = 0;

  final List<String> _avatarOptions = ['👤', '👨', '👩', '🧑', '👦', '👧', '🧔', '👱‍♀️', '👱‍♂️'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LanguageProvider>();
      setState(() {
        _selectedLanguage = provider.currentLanguage;
        _availableAllergens = Map.from(provider.allergenLabels);
      });
    });
  }
  
  void _updateAllergenLabels() {
    final provider = context.read<LanguageProvider>();
    setState(() {
      _availableAllergens = Map.from(provider.allergenLabels);
    });
    debugPrint('Allergen labels updated for language: $_selectedLanguage');
  }
  
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
    } else if (_currentStep == 1) {
      // After language selection, update allergen labels before moving to allergen selection
      _updateAllergenLabels();
      setState(() => _currentStep++);
    } else if (_currentStep < 3) {
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

  Future<void> _saveProfile() async {
    final profile = UserProfile(
      name: _nameController.text.trim(),
      allergens: _selectedAllergens.toList(),
      customAllergens: _customAllergens,
      language: _selectedLanguage,
      avatarEmoji: _selectedAvatar,
      avatarPhotoPath: null,
    );

    final success = await _profileService.saveProfile(profile);
    
    if (!mounted) return;
    
    if (success) {
      final languageProvider = context.read<LanguageProvider>();
      await languageProvider.changeLanguage(_selectedLanguage);
      _updateAllergenLabels();
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      final languageProvider = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.text('profileSaveFailed')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addCustomAllergen() {
    final allergen = _customAllergenController.text.trim();
    if (allergen.isNotEmpty) {
      setState(() {
        _customAllergenController.clear();
      });
    }
  }

  void _removeCustomAllergen(String allergen) {
    setState(() {});
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
              value: (_currentStep + 1) / 4,
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
        return _buildLanguageSelectionStep();
      case 2:
        return _buildAllergenSelectionStep();
      case 3:
        return _buildPreferencesStep();
      default:
        return _buildWelcomeStep();
    }
  }

  Widget _buildWelcomeStep() {
    final strings = context.watch<LanguageProvider>().strings;
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
          Center(
            child: Text(
              strings['welcomeTitle'] ?? 'Welcome to AllerScan',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              strings['welcomeSubtitle'] ?? 'Your personal allergy detection assistant',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            strings['chooseEmojiAvatar'] ?? 'Choose an emoji avatar',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _avatarOptions.map((emoji) {
              final isSelected = _selectedAvatar == emoji;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedAvatar = emoji;
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
          Text(
            strings['whatsYourName'] ?? "What's your name?",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: strings['enterYourName'] ?? 'Enter your name',
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
                return strings['pleaseEnterYourName'] ?? 'Please enter your name';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllergenSelectionStep() {
    final strings = context.watch<LanguageProvider>().strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          strings['selectYourAllergens'] ?? 'Select Your Allergens',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings['chooseAllAllergens'] ?? 'Choose all allergens you need to avoid',
          style: const TextStyle(
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
        Text(
          strings['addCustomAllergens'] ?? 'Add Custom Allergens',
          style: const TextStyle(
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
                  hintText: strings['hintCustomAllergens'] ?? 'e.g., Corn, Celery',
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
      ],
    );
  }

  Widget _buildLanguageSelectionStep() {
    final languageProvider = context.watch<LanguageProvider>();
    final strings = languageProvider.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          strings['chooseLanguage'] ?? 'Choose Your Language',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings['languageHelp'] ?? 'Select your preferred language for allergen detection',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 32),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedLanguage == 'fr'
                      ? strings['languageInfoFr'] ?? 'Les allergènes seront affichés en français et la détection fonctionnera mieux avec les étiquettes en français.'
                      : strings['languageInfo'] ?? 'Allergens will be displayed in English and detection will work best with English labels.',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPreferencesStep() {
    final strings = context.watch<LanguageProvider>().strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          strings['almostDone'] ?? 'Almost Done!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings['reviewYourProfile'] ?? 'Review your profile',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          strings['summary'] ?? 'Summary',
          style: const TextStyle(
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
      onTap: () async {
        setState(() => _selectedLanguage = code);
        await context.read<LanguageProvider>().changeLanguage(code);
        _updateAllergenLabels();
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
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 20),
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
    final strings = context.watch<LanguageProvider>().strings;
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedLanguage == 'fr' ? '🇫🇷' : '🇬🇧',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedLanguage == 'fr'
                          ? strings['languageFrench'] ?? 'Français'
                          : strings['languageEnglish'] ?? 'English',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            strings['allergensToAvoid'] ?? 'Allergens to avoid:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedAllergens.isEmpty && _customAllergens.isEmpty)
            Text(
              strings['noneSelected'] ?? 'None selected',
              style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
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
