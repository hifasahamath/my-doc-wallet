import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

/// Wraps third-party scanner and file picker APIs.
///
/// Returns file paths on success, `null` on cancellation, and throws
/// descriptive exceptions on failure so callers can display meaningful
/// error messages instead of silently doing nothing.
class ImportService {
  /// Supported file extensions for import.
  static const List<String> supportedExtensions = [
    'pdf', 'jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif', 'tiff', 'tif',
    'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv', 'rtf', 'heic', 'heif'
  ];

  /// Open the device document scanner.
  /// Returns a list of cropped/straightened image paths, or `null` if the
  /// user cancelled.
  Future<List<String>?> scanDocuments() async {
    // Request camera permission first
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    if (status.isPermanentlyDenied) {
      throw ImportException(
        'Camera permission is permanently denied. '
        'Please enable it in your device Settings.',
        isPermanentlyDenied: true,
      );
    }
    if (!status.isGranted) {
      throw ImportException('Camera permission is required to scan documents.');
    }

    try {
      final pictures = await CunningDocumentScanner.getPictures(
        scannerSource: ScannerSource.cameraAndGallery,
      );
      if (pictures != null && pictures.isNotEmpty) {
        return pictures;
      }
      return null; // User cancelled
    } on PlatformException catch (e) {
      throw ImportException('Scanner failed: ${e.message}');
    }
  }

  /// Open the system file picker to select a PDF or image file.
  /// Returns the absolute file path, or `null` if the user cancelled.
  Future<String?> pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
      );

      if (result.isEmpty) {
        return null; // User cancelled
      }

      final file = result.first;
      if (file.path == null || file.path!.isEmpty) {
        throw ImportException(
          'The selected file could not be accessed. '
          'Please try selecting a different file.',
        );
      }

      String path = file.path!;
      
      // Android file picker sometimes caches files without extensions (e.g., from Drive).
      // Append the original extension so the app can detect fileType correctly.
      if (file.extension != null && file.extension!.isNotEmpty) {
        final ext = file.extension!.toLowerCase();
        if (!path.toLowerCase().endsWith('.$ext')) {
          final newPath = '$path.$ext';
          try {
            await File(path).rename(newPath);
            path = newPath;
          } catch (_) {
            // If rename fails, try copying
            try {
              await File(path).copy(newPath);
              path = newPath;
            } catch (_) {}
          }
        }
      }

      return path;
    } on PlatformException catch (e) {
      throw ImportException('File picker failed: ${e.message}');
    }
  }
}

/// Exception thrown by [ImportService] when an operation fails.
class ImportException implements Exception {
  final String message;
  final bool isPermanentlyDenied;

  const ImportException(this.message, {this.isPermanentlyDenied = false});

  @override
  String toString() => message;
}
