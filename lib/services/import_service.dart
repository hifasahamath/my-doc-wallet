import 'package:file_picker/file_picker.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

/// Wraps third-party scanner and file picker for testing and easy access.
class ImportService {
  /// Open the device document scanner.
  /// Returns a list of cropped/straightened image paths.
  Future<List<String>?> scanDocuments() async {
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        scannerSource: ScannerSource.cameraAndGallery,
      );
      if (pictures != null && pictures.isNotEmpty) {
        return pictures;
      }
    } catch (e) {
      // PlatformException or user cancelled
    }
    return null;
  }

  /// Open the system file picker to select a PDF or image file.
  /// Returns the file path.
  Future<String?> pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.isNotEmpty && result.first.path != null) {
        return result.first.path;
      }
    } catch (e) {
      // User cancelled or error
    }
    return null;
  }
}
