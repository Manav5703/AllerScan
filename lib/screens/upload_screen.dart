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
    final XFile? pickedImage = await showDialog<XFile?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, await _picker.pickImage(source: ImageSource.camera));
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, await _picker.pickImage(source: ImageSource.gallery));
            },
            child: const Text('Gallery'),
          ),
        ],
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
      appBar: AppBar(
        title: const Text('Scan Label'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _image == null ? Colors.grey[300] : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 16.0),
              child: _image == null
                  ? const Center(child: Text('Image Preview', style: TextStyle(fontSize: 18)))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
            ),
            ElevatedButton(
              onPressed: _captureImage,
              child: const Text('Capture or Select Image'),
            ),
          ],
        ),
      ),
    );
  }
}

// Fixed cropping screen with correct crop_your_image API
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
              // Trigger the crop operation
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
                    // This will be called when crop is triggered
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
                  'Drag the corners to crop the image. Focus on the ingredients label.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Trigger the crop operation
                        _cropController.crop();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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