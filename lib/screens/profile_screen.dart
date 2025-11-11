import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/language_provider.dart';
import '../widgets/avatar_display.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _customAllergenController = TextEditingController();

  Set<String> _selectedAllergens = {};
  List<String> _customAllergens = [];
  String _selectedLanguage = 'en';
  String? _selectedAvatar;
  String? _avatarPhotoPath;
  final ImagePicker _picker = ImagePicker();

  final List<String> _avatarOptions = ['👤', '👨', '👩', '🧑', '👦', '👧', '🧔', '👱‍♀️', '👱‍♂️'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _customAllergenController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.loadProfile();
    if (profile != null) {
      setState(() {
        _profile = profile;
        _nameController.text = profile.name;
        _selectedAllergens = profile.allergens.toSet();
        _customAllergens = List.from(profile.customAllergens);
        _selectedLanguage = profile.language;
        _selectedAvatar = profile.avatarEmoji;
        _avatarPhotoPath = profile.avatarPhotoPath;
        _isLoading = false;
      });
      print('Profile loaded with language: ${profile.language}');
    } else {
      if (!mounted) return;
      final provider = context.read<LanguageProvider>();
      setState(() {
        _isLoading = false;
        _selectedLanguage = provider.currentLanguage;
      });
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
    if (!_formKey.currentState!.validate()) return;

    final languageProvider = context.read<LanguageProvider>();
    final updatedProfile = UserProfile(
      name: _nameController.text.trim(),
      allergens: _selectedAllergens.toList(),
      customAllergens: _customAllergens,
      language: _selectedLanguage,
      avatarEmoji: _selectedAvatar,
      avatarPhotoPath: _avatarPhotoPath,
    );

    final success = await _profileService.updateProfile(updatedProfile);
    
    if (!mounted) return;
    
    if (success) {
      setState(() {
        _profile = updatedProfile;
        _isEditing = false;
      });
      await languageProvider.changeLanguage(_selectedLanguage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.text('profileUpdated')),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.text('profileUpdateFailed')),
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

  Future<void> _confirmDeleteProfile() async {
    final strings = context.read<LanguageProvider>().strings;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings['deleteProfile'] ?? 'Delete Profile'),
        content: Text(
          strings['deleteProfileQuestion'] ??
              'Are you sure you want to delete your profile? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings['cancel'] ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(strings['delete'] ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _profileService.deleteProfile();
      if (!mounted) return;
      
      if (success) {
        await context.read<LanguageProvider>().changeLanguage('en');
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final strings = languageProvider.strings;
    final editingAllergenLabels = languageProvider.allergenLabelsFor(_selectedLanguage);
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(strings['profileTitle'] ?? 'Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings['profileTitle'] ?? 'Profile')),
        body: Center(
          child: Text(strings['profileNotFound'] ?? 'No profile found. Please complete onboarding.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings['profileTitle'] ?? 'Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditing = false);
                _loadProfile(); // Reset changes
              },
            ),
        ],
      ),
      body: _isEditing
          ? _buildEditMode(strings, editingAllergenLabels, languageProvider)
          : _buildViewMode(strings, languageProvider),
    );
  }

  Widget _buildViewMode(Map<String, String> strings, LanguageProvider languageProvider) {
    final allergenLabels = languageProvider.allergenLabelsFor(_profile!.language);
    final languageBadge = languageProvider.languageBadge(_profile!.language);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                AvatarDisplay(
                  profile: _profile,
                  size: 100,
                ),
                const SizedBox(height: 16),
                Text(
                  _profile!.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    languageBadge,
                    style: TextStyle(
                      color: Colors.teal.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Allergens section
          Text(
            strings['myAllergens'] ?? 'My Allergens',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_profile!.allergens.isEmpty && _profile!.customAllergens.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  strings['noAllergensSelected'] ?? 'No allergens selected',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_profile!.allergens.isNotEmpty) ...[
                  Text(
                    strings['standardAllergens'] ?? 'Standard Allergens',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _profile!.allergens.map((key) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          allergenLabels[key] ?? key,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (_profile!.customAllergens.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    strings['customAllergensTitle'] ?? 'Custom Allergens',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _profile!.customAllergens.map((allergen) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          allergen,
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 32),
          // Delete profile button
          Center(
            child: OutlinedButton.icon(
              onPressed: _confirmDeleteProfile,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: Text(
                strings['deleteProfile'] ?? 'Delete Profile',
                style: const TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(
    Map<String, String> strings,
    Map<String, String> editingAllergenLabels,
    LanguageProvider languageProvider,
  ) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings['editProfile'] ?? 'Edit Profile',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            // Avatar selection
            Text(
              strings['avatarLabel'] ?? 'Avatar',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
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
                            _avatarPhotoPath != null
                                ? strings['customPhotoSelected'] ?? 'Custom Photo Selected'
                                : strings['uploadCustomPhoto'] ?? 'Upload Custom Photo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _avatarPhotoPath != null ? Colors.teal.shade700 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _avatarPhotoPath != null
                                ? strings['customPhotoTap'] ?? 'Tap to change'
                                : strings['chooseFromGallery'] ?? 'Choose from gallery',
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
            const SizedBox(height: 12),
            Center(
              child: Text(
                strings['orLabel'] ?? 'OR',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings['chooseEmojiAvatar'] ?? 'Choose an emoji avatar',
              style: const TextStyle(
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
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Name
            Text(
              strings['nameLabel'] ?? 'Name',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 24),
            // Language
            Text(
              strings['languageLabel'] ?? 'Language',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLanguageOption('en', '🇬🇧', languageProvider, strings),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLanguageOption('fr', '🇫🇷', languageProvider, strings),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Allergens
            Text(
              strings['allergensLabel'] ?? 'Allergens',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...editingAllergenLabels.entries.map((entry) {
              final isSelected = _selectedAllergens.contains(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
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
                    padding: const EdgeInsets.all(12),
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
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            // Custom allergens
            Text(
              strings['customAllergensLabel'] ?? 'Custom Allergens',
              style: const TextStyle(
                fontSize: 16,
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
            if (_customAllergens.isNotEmpty) ...[
              const SizedBox(height: 12),
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
            const SizedBox(height: 32),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  strings['saveChanges'] ?? 'Save Changes',
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
      ),
    );
  }

  Widget _buildLanguageOption(
    String code,
    String flag,
    LanguageProvider languageProvider,
    Map<String, String> strings,
  ) {
    final isSelected = _selectedLanguage == code;
    return InkWell(
      onTap: () {
        setState(() => _selectedLanguage = code);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
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
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              languageProvider.languageName(code),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
