import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:typed_data';
import '../utils/text_normalization.dart';
import '../utils/allergen_detector.dart';
import 'results_screen.dart';

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

  @override
  void initState() {
    super.initState();
    AllergenDictionary.loadEnglish().then((d) {
      setState(() {
        _dict = d;
        _detector = AllergenDetector(d, enableFuzzy: true);
      });
    });
  }

  Future<void> _captureImage() async {
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
            const Text(
              'Select Image Source',
              style: TextStyle(
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
              title: const Text(
                'Camera',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Take a new photo'),
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
              title: const Text(
                'Gallery',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context, await _picker.pickImage(source: ImageSource.gallery));
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
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
      print('Starting OCR for image: $imagePath');
      
      // Try both PSM 4 and PSM 6, pick the better result
      String text4 = await FlutterTesseractOcr.extractText(
        imagePath,
        language: 'eng',
        args: {
          'psm': '4',
          'preserve_interword_spaces': '1',
          'tessdata': 'assets/tessdata/',
        },
      );

      String text6 = await FlutterTesseractOcr.extractText(
        imagePath,
        language: 'eng',
        args: {
          'psm': '6',
          'preserve_interword_spaces': '1',
          'tessdata': 'assets/tessdata/',
        },
      );

      print('Raw OCR Text (PSM 4): $text4');
      print('Raw OCR Text (PSM 6): $text6');

      // Pick the better result based on allergen detection
      String chosenText = text4;
      if (_detector != null) {
        final hits4 = _detector!.detect(text4);
        final hits6 = _detector!.detect(text6);
        print('PSM 4 hits: ${hits4.length}, PSM 6 hits: ${hits6.length}');
        if (hits6.length > hits4.length) {
          chosenText = text6;
        }
      }

      // Detect allergens on chosen text
      List<String> hard = [];
      List<String> soft = [];
      if (_detector != null) {
        final hits = _detector!.detect(chosenText);
        hard = hits.where((h) => h.hard).map((h) => h.allergenKey).toSet().toList()..sort();
        soft = hits.where((h) => !h.hard).map((h) => h.allergenKey).toSet().toList()..sort();
        print('Detected hard allergens: $hard');
        print('Detected soft allergens: $soft');
      }

      final filteredText = _filterIngredients(chosenText);
      final normalizedForDisplay = filteredText.isNotEmpty
          ? TextNormalization.normalizeBasic(filteredText)
          : 'No ingredients found (raw text: $chosenText)';

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
          ),
        ),
      );
    } catch (e) {
      print('OCR Error: $e');
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
          ),
        ),
      );
    }
  }

  String _filterIngredients(String text) {
    List<String> lines = text.split('\n');
    bool foundIngredients = false;
    StringBuffer ingredients = StringBuffer();
    for (String line in lines) {
      line = line.trim().toLowerCase();
      if (line.contains('ingredients') || line.contains('ingrédients') ||
          line.contains('contains') || line.contains('contient')) {
        foundIngredients = true;
      } else if (foundIngredients && line.isNotEmpty && !line.contains('nutrition') &&
                 !line.contains('net weight')) {
        ingredients.write('$line\n');
      } else if (line.isEmpty) {
        foundIngredients = false;
      }
    }
    return ingredients.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Scan Label'),
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
                                'No image selected',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the button below to get started',
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
                        _image == null ? 'Capture or Select Image' : 'Change Image',
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
                            const Text(
                              'Tips for best results',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTip('Ensure good lighting'),
                        _buildTip('Keep the label flat and in focus'),
                        _buildTip('Avoid shadows and glare'),
                        _buildTip('Capture the entire ingredients section'),
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
                      const Text(
                        'Analyzing ingredients...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This may take a moment',
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
