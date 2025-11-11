import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../utils/text_normalization.dart';
import '../utils/allergen_detector.dart';
import 'results_screen.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/language_provider.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  AllergenDictionary? _dict;
  AllergenDetector? _detector;
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isProcessing = false;
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadAllergenDictionary();
  }
  
  Future<void> _loadAllergenDictionary() async {
    try {
      final profile = _userProfile ?? await _profileService.loadProfile();
      final language = profile?.language ?? 'en';
      
      print('Loading allergen dictionary for language: $language');
      print('User profile: ${profile?.name}, language: ${profile?.language}');
      
      AllergenDictionary dict;
      if (language == 'fr') {
        print('Attempting to load French dictionary...');
        dict = await AllergenDictionary.loadFrench();
      } else {
        print('Loading English dictionary...');
        dict = await AllergenDictionary.loadEnglish();
      }
      
      print('Dictionary loaded with ${dict.allergenToTerms.length} allergens');
      print('Allergen keys: ${dict.allergenToTerms.keys.toList()}');
          
      setState(() {
        _dict = dict;
        _detector = AllergenDetector(dict, enableFuzzy: true);
      });
      
      print('Allergen dictionary loaded successfully for $language');
    } catch (e) {
      print('ERROR loading allergen dictionary: $e');
      // Fallback to English dictionary
      final dict = await AllergenDictionary.loadEnglish();
      setState(() {
        _dict = dict;
        _detector = AllergenDetector(dict, enableFuzzy: true);
      });
    }
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.loadProfile();
    setState(() {
      _userProfile = profile;
    });
  }

  // Refresh profile (call this when returning from profile screen)
  void _refreshProfile() async {
    await _loadProfile();
    // Reload allergen dictionary when profile changes (for language switch)
    _loadAllergenDictionary();
  }

  Future<void> _captureImage() async {
    final strings = context.read<LanguageProvider>().strings;
    final XFile? pickedImage = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              strings['uploadSheetTitle'] ?? 'Select Image Source',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: Colors.teal.shade600),
              ),
              title: Text(
                strings['uploadCameraTitle'] ?? 'Camera',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(strings['uploadCameraSubtitle'] ?? 'Take a new photo'),
              onTap: () async {
                Navigator.pop(context, await _picker.pickImage(source: ImageSource.camera));
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library, color: Colors.blue.shade600),
              ),
              title: Text(
                strings['uploadGalleryTitle'] ?? 'Gallery',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(strings['uploadGallerySubtitle'] ?? 'Choose from gallery'),
              onTap: () async {
                Navigator.pop(context, await _picker.pickImage(source: ImageSource.gallery));
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(strings['cancel'] ?? 'Cancel'),
            ),
          ],
        ),
      ),
    );

    if (pickedImage == null) return;

    // Navigate to cropping screen
    final croppedImage = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (context) => CropScreen(imagePath: pickedImage.path),
      ),
    );

    if (croppedImage == null) return;

    // Save cropped image to temporary file
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(croppedImage);

    setState(() {
      _image = tempFile;
    });
    await _performOCR(tempFile.path);
  }

  Future<void> _performOCR(String imagePath) async {
    setState(() => _isProcessing = true);

    try {
      print('Starting enhanced OCR for image: $imagePath');

      // OCR configurations to try (without image preprocessing for now)
      final List<Map<String, String>> ocrConfigs = [
        // PSM modes with character whitelist including French accented characters
        {'psm': '4', 'oem': '1', 'char_whitelist': 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789,.()/-%& éèêëàâäôöùûüÿçÉÈÊËÀÂÄÔÖÙÛÜŸÇœŒæÆ'},
        {'psm': '6', 'oem': '1', 'char_whitelist': 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789,.()/-%& éèêëàâäôöùûüÿçÉÈÊËÀÂÄÔÖÙÛÜŸÇœŒæÆ'},
        {'psm': '11', 'oem': '1', 'char_whitelist': 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789,.()/-%& éèêëàâäôöùûüÿçÉÈÊËÀÂÄÔÖÙÛÜŸÇœŒæÆ'},
        {'psm': '13', 'oem': '1', 'char_whitelist': 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789,.()/-%& éèêëàâäôöùûüÿçÉÈÊËÀÂÄÔÖÙÛÜŸÇœŒæÆ'},
        {'psm': '3', 'oem': '1', 'char_whitelist': 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789,.()/-%& éèêëàâäôöùûüÿçÉÈÊËÀÂÄÔÖÙÛÜŸÇœŒæÆ'},

        // Legacy engine variants (fallback)
        {'psm': '4', 'oem': '0', 'char_whitelist': 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789,.()/-%& éèêëàâäôöùûüÿçÉÈÊËÀÂÄÔÖÙÛÜŸÇœŒæÆ'},
        {'psm': '6', 'oem': '0', 'char_whitelist': 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789,.()/-%& éèêëàâäôöùûüÿçÉÈÊËÀÂÄÔÖÙÛÜŸÇœŒæÆ'},
      ];

      String? bestText;
      int bestScore = 0;
      List<String> bestHardAllergens = [];
      List<String> bestSoftAllergens = [];

      // Try each OCR configuration
      for (final config in ocrConfigs) {
        try {
          // Perform OCR with this configuration
          final text = await FlutterTesseractOcr.extractText(
            imagePath,
            language: _userProfile?.language == 'fr' ? 'fra' : 'eng',
            args: {
              'psm': config['psm']!,
              'oem': config['oem']!,
              'tessedit_char_whitelist': config['char_whitelist']!,
              'preserve_interword_spaces': '1',
              'tessdata': 'assets/tessdata/',
            },
          );

          if (text.trim().isEmpty) continue;

          print('OCR Result (PSM ${config['psm']}, OEM ${config['oem']}): $text');

          // Detect allergens
          if (_detector != null) {
            print('Detecting allergens with dictionary: ${_detector!.dict.allergenToTerms.keys}');
            final hits = _detector!.detect(text);
            print('Allergen detection hits: ${hits.length}');
            
            // Debug each hit
            for (var hit in hits) {
              print('Hit: ${hit.allergenKey}, term: "${hit.matchedTerm}", confidence: ${hit.confidence}, section: ${hit.section}');
            }
            
            final hardAllergens = hits.where((h) => h.hard).map((h) => h.allergenKey).toSet().toList()..sort();
            final softAllergens = hits.where((h) => !h.hard).map((h) => h.allergenKey).toSet().toList()..sort();
            print('Hard allergens: $hardAllergens');
            print('Soft allergens: $softAllergens');

            // Enhanced scoring: weight by confidence and prioritize hard allergens
            double hardScore = hardAllergens.length * 3.0; // Hard allergens worth 3x
            double softScore = softAllergens.length * 1.0; // Soft allergens worth 1x
            double confidenceScore = hits.fold(0.0, (sum, hit) => sum + hit.confidence); // Add confidence scores
            int score = (hardScore + softScore + (confidenceScore * 0.5) + (text.length ~/ 20)).toInt();

            print('Score: $score (Hard: ${hardAllergens.length}, Soft: ${softAllergens.length}, Confidence: ${confidenceScore.toStringAsFixed(2)}, Text length: ${text.length})');

            if (score > bestScore) {
              bestScore = score;
              bestText = text;
              bestHardAllergens = hardAllergens;
              bestSoftAllergens = softAllergens;
            }
          }

        } catch (e) {
          print('OCR error with config ${config['psm']}_${config['oem']}: $e');
        }
      }

      // Use best result or fallback to original method
      String chosenText;
      List<String> hard;
      List<String> soft;

      if (bestText != null && bestScore > 0) {
        chosenText = bestText;
        hard = bestHardAllergens;
        soft = bestSoftAllergens;
        print('Using enhanced OCR result (Score: $bestScore)');
      } else {
        // Fallback to original method
        print('Using fallback OCR method');
        chosenText = await _fallbackOCR(imagePath);
        if (_detector != null) {
          final hits = _detector!.detect(chosenText);
          hard = hits.where((h) => h.hard).map((h) => h.allergenKey).toSet().toList()..sort();
          soft = hits.where((h) => !h.hard).map((h) => h.allergenKey).toSet().toList()..sort();
        } else {
          hard = [];
          soft = [];
        }
      }

      print('Final OCR Text: $chosenText');
      print('Detected hard allergens: $hard');
      print('Detected soft allergens: $soft');

      final filteredText = _filterIngredients(chosenText);
      final normalizedForDisplay = filteredText.isNotEmpty
          ? TextNormalization.normalizeBasic(filteredText)
          : '';

      final strings = context.read<LanguageProvider>().strings;

      if (normalizedForDisplay.isEmpty) {
        print('No ingredients header detected. Prompting user to retry.');
        setState(() => _isProcessing = false);

        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(strings['uploadMissingIngredientsTitle'] ?? 'No ingredients found'),
              content: Text(strings['uploadMissingIngredientsMessage'] ??
                  'We couldn\'t find the word "Ingredients" in this photo. Please retake or choose another shot.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(strings['cancel'] ?? 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _captureImage();
                  },
                  child: Text(strings['retryCta'] ?? 'Try Again'),
                ),
              ],
            );
          },
        );
        return;
      }

      print('Final filtered text: $normalizedForDisplay');

      setState(() => _isProcessing = false);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            extractedIngredientsText: normalizedForDisplay,
            hardAllergens: hard,
            softAllergens: soft,
            imageFile: _image,
            userProfile: _userProfile,
          ),
        ),
      ).then((_) {
        _refreshProfile();
      });

    } catch (e) {
      print('Enhanced OCR Error: $e');
      setState(() => _isProcessing = false);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            extractedIngredientsText: 'Error occurred during OCR: $e',
            hardAllergens: [],
            softAllergens: [],
            imageFile: _image,
            userProfile: _userProfile,
          ),
        ),
      ).then((_) {
        _refreshProfile();
      });
    }
  }

  // Fallback OCR method (original implementation)
  Future<String> _fallbackOCR(String imagePath) async {
    final ocrLanguage = _userProfile?.language == 'fr' ? 'fra' : 'eng';
    print('Using fallback OCR with language: $ocrLanguage');
    
    String text4 = await FlutterTesseractOcr.extractText(
      imagePath,
      language: ocrLanguage,
      args: {
        'psm': '4',
        'preserve_interword_spaces': '1',
        'tessdata': 'assets/tessdata/',
      },
    );

    String text6 = await FlutterTesseractOcr.extractText(
      imagePath,
      language: ocrLanguage,
      args: {
        'psm': '6',
        'preserve_interword_spaces': '1',
        'tessdata': 'assets/tessdata/',
      },
    );

    print('Fallback OCR Text (PSM 4): $text4');
    print('Fallback OCR Text (PSM 6): $text6');

    if (_detector != null) {
      final hits4 = _detector!.detect(text4);
      final hits6 = _detector!.detect(text6);

      // Enhanced scoring for fallback
      double score4 = _calculateScore(hits4, text4);
      double score6 = _calculateScore(hits6, text6);

      print('Fallback scores - PSM 4: ${score4.toStringAsFixed(2)}, PSM 6: ${score6.toStringAsFixed(2)}');

      return score6 > score4 ? text6 : text4;
    }

    return text4; // Default fallback
  }

  double _calculateScore(List<dynamic> hits, String text) {
    final hardAllergens = hits.where((h) => h.hard).map((h) => h.allergenKey).toSet().toList();
    final softAllergens = hits.where((h) => !h.hard).map((h) => h.allergenKey).toSet().toList();
    final confidenceScore = hits.fold(0.0, (sum, hit) => sum + hit.confidence);

    return (hardAllergens.length * 3.0) + softAllergens.length + (confidenceScore * 0.5) + (text.length ~/ 20);
  }

  String _filterIngredients(String text) {
    List<String> lines = text.split('\n');
    bool foundIngredients = false;
    StringBuffer ingredients = StringBuffer();
    
    // Enhanced patterns for both English and French
    final ingredientHeaders = [
      'ingredients', 'ingrédients', 'contains', 'contient', 'composition',
      'liste des ingrédients', 'liste d\'ingrédients'
    ];
    
    final endPatterns = [
      'nutrition', 'nutritional', 'valeurs nutritionnelles', 'valeur nutritive',
      'net weight', 'poids net', 'best before', 'à consommer avant',
      'store in', 'conserver dans', 'keep refrigerated', 'garder réfrigéré'
    ];
    
    for (String line in lines) {
      line = line.trim().toLowerCase();
      
      // Check if this line is an ingredient header
      bool isHeader = ingredientHeaders.any((header) => line.contains(header));
      if (isHeader) {
        foundIngredients = true;
        // Include the header line itself
        ingredients.write('$line\n');
        continue;
      }
      
      // Check if we should stop collecting ingredients
      bool isEndSection = endPatterns.any((pattern) => line.contains(pattern));
      if (foundIngredients && isEndSection) {
        foundIngredients = false;
        continue;
      }
      
      // Add ingredient lines
      if (foundIngredients && line.isNotEmpty) {
        ingredients.write('$line\n');
      } else if (line.isEmpty && foundIngredients) {
        // Empty line might indicate end of section, but don't immediately stop
        // in case there are multi-paragraph ingredients
        ingredients.write('\n');
      }
    }
    
    return ingredients.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LanguageProvider>().strings;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(strings['uploadAppBarTitle'] ?? 'Scan Label'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            strings['uploadInstructions'] ??
                                'Position the ingredient label clearly in the frame for best results',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Image preview
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha((0.1 * 255).toInt()),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _image == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                strings['uploadNoImageTitle'] ?? 'No image selected',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                strings['uploadNoImageSubtitle'] ?? 'Tap the button below to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              _image!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                  ),
                  const SizedBox(height: 32),
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _captureImage,
                      icon: const Icon(Icons.camera_alt, size: 24),
                      label: Text(
                        _image == null
                            ? strings['uploadPrimaryButton'] ?? 'Capture or Select Image'
                            : strings['uploadPrimaryButtonChange'] ?? 'Change Image',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tips section
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
                            Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              strings['uploadTipsTitle'] ?? 'Tips for best results',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTip(strings['uploadTipLighting'] ?? 'Ensure good lighting'),
                        _buildTip(strings['uploadTipFocus'] ?? 'Keep the label flat and in focus'),
                        _buildTip(strings['uploadTipShadows'] ?? 'Avoid shadows and glare'),
                        _buildTip(strings['uploadTipFullLabel'] ?? 'Capture the entire ingredients section'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withAlpha((0.7 * 255).toInt()),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.teal.shade600),
                      const SizedBox(height: 20),
                      Text(
                        strings['uploadProcessingTitle'] ?? 'Analyzing with enhanced OCR...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings['uploadProcessingSubtitle'] ??
                            'Testing multiple recognition modes for best accuracy',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Crop screen with polished UI
class CropScreen extends StatefulWidget {
  final String imagePath;

  const CropScreen({super.key, required this.imagePath});

  @override
  _CropScreenState createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  Uint8List? _imageBytes;
  final CropController _cropController = CropController();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final file = File(widget.imagePath);
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_imageBytes == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.teal.shade600),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Crop Image', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () {
              _cropController.crop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Crop(
                  image: _imageBytes!,
                  controller: _cropController,
                  onCropped: (croppedImage) {
                    Navigator.pop(context, croppedImage);
                  },
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Drag the corners to crop the image',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Focus on the ingredients label for best results',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text('Cancel', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.white, width: 2),
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
                          _cropController.crop();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.teal.shade600,
                          foregroundColor: Colors.white,
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
    );
  }
}
