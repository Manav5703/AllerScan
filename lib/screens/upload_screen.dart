import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String _extractedText = 'Extracted text will appear here';

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
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
        _extractedText = 'Processing...'; // Show loading state
      });
      _performOCR(pickedImage.path);
    } else {
      String testImagePath = 'data/label_0.png';
      if (await File(testImagePath).exists()) {
        setState(() {
          _image = File(testImagePath);
          _extractedText = 'Processing...';
        });
        _performOCR(testImagePath);
      } else {
        setState(() {
          _extractedText = 'Test image not found';
        });
      }
    }
  }

  Future<void> _performOCR(String imagePath) async {
    try {
      String text = await FlutterTesseractOcr.extractText(
        imagePath,
        language: 'eng+fra',
        args: {
          'psm': '4',
          'preserve_interword_spaces': '1',
          'tessdata': 'assets/tessdata/',
        },
      );
      print('Raw OCR Text: $text');
      String filteredText = _filterIngredients(text);
      setState(() {
        _extractedText = filteredText.isNotEmpty ? filteredText : 'No ingredients found (raw text: $text)';
      });
    } catch (e) {
      setState(() {
        _extractedText = 'Error: $e';
      });
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
            onPressed: () {
              // Add info/about screen later
            },
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
              height: 250, // Increased for better visibility
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
            const SizedBox(height: 20),
            if (_extractedText != 'Extracted text will appear here' && _extractedText != 'Processing...')
              const Text(
                'Ingredients Detected:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            if (_extractedText != 'Extracted text will appear here' && _extractedText != 'Processing...')
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  _extractedText,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}