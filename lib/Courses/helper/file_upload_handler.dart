import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FileUploadHandler {
  PlatformFile? _pickedFile;

  Future<bool> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, // Use `type` instead of `fileType`
        allowedExtensions: ['pdf'], // Specify allowed extensions for PDF files
      );

      if (result != null && result.files.isNotEmpty) {
        _pickedFile = result.files.first;
        return true;
      }
      return false;
    } catch (e) {
      print('File pick error: $e');
      return false;
    }
  }

  Future<String> uploadFile(String storagePath) async {
    if (_pickedFile == null) throw Exception('No file selected');

    try {
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child(storagePath)
          .child('${DateTime.now().millisecondsSinceEpoch}.pdf');

      if (kIsWeb) {
        // For web platform
        final UploadTask uploadTask = ref.putData(
          _pickedFile!.bytes!,
          SettableMetadata(contentType: 'application/pdf'),
        );
        await uploadTask;
      } else {
        // For mobile/desktop platforms
        final UploadTask uploadTask = ref.putFile(
          File(_pickedFile!.path!),
          SettableMetadata(contentType: 'application/pdf'),
        );
        await uploadTask;
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print('Upload error: $e');
      throw Exception('File upload failed: $e');
    }
  }
}
