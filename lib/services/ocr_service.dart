import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:my_doc_wallet/services/file_storage_service.dart';

/// On-device OCR using Google ML Kit.
class OcrService {
  final FileStorageService _storage;
  final _recognizer = TextRecognizer();

  OcrService(this._storage);

  /// Extract text from an encrypted image file.
  Future<String> extractText(String relativePath) async {
    // Decrypt to temp for ML Kit processing
    final tempPath =
        await _storage.decryptToTemp(relativePath, 'ocr_temp.jpg');
    try {
      final inputImage = InputImage.fromFilePath(tempPath);
      final result = await _recognizer.processImage(inputImage);
      return result.text;
    } finally {
      await File(tempPath).delete().catchError((_) => File(''));
    }
  }

  void dispose() {
    _recognizer.close();
  }
}
