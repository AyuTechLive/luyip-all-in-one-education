import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';

// Add these imports for web support
import 'package:universal_html/html.dart' as html;
import 'package:image_picker_web/image_picker_web.dart';

class ImageUploadHandler {
  // For non-web platforms
  File? _imageFile;
  // For web platform
  Uint8List? _webImageBytes;
  String? _webImageName;

  final picker = ImagePicker();
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  // Preview widget that works on both web and mobile
  Widget getImagePreview({
    required double height,
    required double width,
    required BorderRadius borderRadius,
  }) {
    if (kIsWeb) {
      if (_webImageBytes != null) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.memory(
            _webImageBytes!,
            height: height,
            width: width,
            fit: BoxFit.cover,
          ),
        );
      }
    } else {
      if (_imageFile != null) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.file(
            _imageFile!,
            height: height,
            width: width,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    // Return placeholder if no image
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No image selected'),
          ],
        ),
      ),
    );
  }

  // Pick image from gallery - works on both platforms
  Future<bool> pickImage() async {
    if (kIsWeb) {
      // Web implementation
      final imageResult = await ImagePickerWeb.getImageAsBytes();
      final imageInfo = await ImagePickerWeb.getImageInfo();

      if (imageResult != null && imageInfo != null) {
        _webImageBytes = imageResult;
        _webImageName = imageInfo.fileName;
        return true;
      }
    } else {
      // Mobile implementation
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
        return true;
      }
    }
    return false;
  }

  // Upload image to Firebase Storage
  Future<String> uploadImageToFirebase(String path) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    firebase_storage.Reference ref = storage.ref('$path/$fileName');
    firebase_storage.UploadTask uploadTask;

    if (kIsWeb) {
      // Web implementation
      if (_webImageBytes == null) {
        throw Exception('No image selected');
      }

      // Get file extension from name or default to jpg
      String extension = 'jpg';
      if (_webImageName != null && _webImageName!.contains('.')) {
        extension = _webImageName!.split('.').last;
      }

      // Set metadata for web upload
      firebase_storage.SettableMetadata metadata =
          firebase_storage.SettableMetadata(contentType: 'image/$extension');

      // Upload bytes for web
      uploadTask = ref.putData(_webImageBytes!, metadata);
    } else {
      // Mobile implementation
      if (_imageFile == null) {
        throw Exception('No image selected');
      }

      String extension = _imageFile!.path.split('.').last;
      firebase_storage.SettableMetadata metadata =
          firebase_storage.SettableMetadata(contentType: 'image/$extension');

      // Upload file for mobile
      uploadTask = ref.putFile(_imageFile!, metadata);
    }

    await uploadTask;
    String downloadURL = await ref.getDownloadURL();
    return downloadURL;
  }

  // Clear the selected image
  void clearImage() {
    _imageFile = null;
    _webImageBytes = null;
    _webImageName = null;
  }

  // Check if image is selected
  bool hasImage() {
    return kIsWeb ? _webImageBytes != null : _imageFile != null;
  }
}
