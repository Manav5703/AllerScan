import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../widgets/avatar_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProfileService _profileService = ProfileService();
  UserProfile? _profile;
  bool _isLoading = true;

  final Map<String, String> _availableAllergens = {
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
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.loadProfile();
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AllerScan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              await Navigator.pushNamed(context, '/profile');
              _loadProfile(); // Reload profile after returning
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  Row(
                    children: [
                      AvatarDisplay(
                        profile: _profile,
                        size: 60,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back,',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              _profile?.name ?? 'User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Your allergens card
                  if (_profile != null && (_profile!.allergens.isNotEmpty || _profile!.customAllergens.isNotEmpty))
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Your Allergens',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ..._profile!.allergens.map((key) => Chip(
                                    label: Text(
                                      _availableAllergens[key] ?? key,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.red.shade100,
                                    padding: EdgeInsets.zero,
                                  )),
                              ..._profile!.customAllergens.map((allergen) => Chip(
                                    label: Text(allergen, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.orange.shade100,
                                    padding: EdgeInsets.zero,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Main action button
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.teal.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withAlpha((0.3 * 255).toInt()),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/upload');
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 60,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Scan Product Label',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Take a photo or upload an image',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Info cards
                  const Text(
                    'How it works',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.photo_camera,
                    title: '1. Capture',
                    description: 'Take a photo of the ingredient label',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.search,
                    title: '2. Analyze',
                    description: 'We scan for allergens in the ingredients',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.check_circle,
                    title: '3. Results',
                    description: 'Get instant alerts about your allergens',
                    color: Colors.green,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).toInt()),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}