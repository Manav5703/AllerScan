import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;

  Future<void> _captureImage() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Label')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: _image == null ? Colors.grey[300] : null,
            margin: const EdgeInsets.all(16.0),
            child: _image == null
                ? const Center(child: Text('Image Preview'))
                : Image.file(_image!, fit: BoxFit.cover),
          ),
          ElevatedButton(
            onPressed: _captureImage,
            child: const Text('Capture Image'),
          ),
        ],
      ),
    );
  }
}