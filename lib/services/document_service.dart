import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

import 'package:my_doc_wallet/core/constants/app_constants.dart';
import 'package:my_doc_wallet/core/utils/file_utils.dart';
import 'package:my_doc_wallet/data/models/document.dart';
import 'package:my_doc_wallet/data/repositories/document_repository.dart';
import 'package:my_doc_wallet/services/file_storage_service.dart';

/// Orchestrates document creation, import, and version management.
class DocumentService {
  final DocumentRepository _repo;
  final FileStorageService _storage;
  final _uuid = const Uuid();

  DocumentService(this._repo, this._storage);

  /// Import a file from the device (PDF or image).
  Future<Document> importFile({
    required String sourcePath,
    required String name,
    required String categoryId,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    List<String> tags = const [],
  }) async {
    final id = _uuid.v4();
    final ext = FileUtils.extension(sourcePath);
    final fileType = ext.isNotEmpty ? ext.toLowerCase() : 'unknown';
    final destFilename = '$id.$ext';
    final sourceFile = File(sourcePath);
    final fileSize = await sourceFile.length();

    // Store encrypted
    final relativePath = await _storage.storeFromPath(sourcePath, destFilename);

    // Generate thumbnail
    String? thumbPath;
    try {
      thumbPath = await _generateThumbnail(sourcePath, id, fileType);
    } catch (_) {
      // Thumbnail generation is best-effort
    }

    final now = DateTime.now();
    final doc = Document(
      id: id,
      name: name,
      categoryId: categoryId,
      documentNumber: documentNumber,
      issueDate: issueDate,
      expiryDate: expiryDate,
      notes: notes,
      filePath: relativePath,
      fileType: fileType,
      thumbnailPath: thumbPath,
      fileSize: fileSize,
      createdAt: now,
      updatedAt: now,
    );

    await _repo.insert(doc);
    if (tags.isNotEmpty) {
      await _repo.setTagsForDocument(id, tags);
    }
    return doc;
  }

  /// Create a document from scanned images, combining them into a PDF.
  Future<Document> createFromScannedImages({
    required List<String> imagePaths,
    required String name,
    required String categoryId,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    List<String> tags = const [],
  }) async {
    final id = _uuid.v4();
    final pdfBytes = await _imagesToPdf(imagePaths);
    final destFilename = '$id.pdf';
    final relativePath = await _storage.storeFile(pdfBytes, destFilename);

    // Thumbnail from first image
    String? thumbPath;
    if (imagePaths.isNotEmpty) {
      try {
        thumbPath = await _generateThumbnail(imagePaths.first, id, 'image');
      } catch (_) {}
    }

    final now = DateTime.now();
    final doc = Document(
      id: id,
      name: name,
      categoryId: categoryId,
      documentNumber: documentNumber,
      issueDate: issueDate,
      expiryDate: expiryDate,
      notes: notes,
      filePath: relativePath,
      fileType: 'pdf',
      thumbnailPath: thumbPath,
      pageCount: imagePaths.length,
      fileSize: pdfBytes.length,
      createdAt: now,
      updatedAt: now,
    );

    await _repo.insert(doc);
    if (tags.isNotEmpty) {
      await _repo.setTagsForDocument(id, tags);
    }
    return doc;
  }

  /// Update document metadata.
  Future<void> updateDocument(Document doc) async {
    await _repo.update(doc.copyWith(updatedAt: DateTime.now()));
  }

  /// Delete a document and its encrypted files.
  Future<void> deleteDocument(String id) async {
    final doc = await _repo.getById(id);
    if (doc != null) {
      await _storage.deleteFile(doc.filePath);
      if (doc.thumbnailPath != null) {
        await _storage.deleteFile(doc.thumbnailPath!);
      }
    }
    await _repo.delete(id);
  }

  /// Convert a list of image paths into a single PDF byte array.
  Future<Uint8List> _imagesToPdf(List<String> imagePaths) async {
    final pdf = pw.Document();

    for (final path in imagePaths) {
      final bytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(bytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }

    return pdf.save();
  }

  /// Generate a thumbnail image from a source file.
  Future<String?> _generateThumbnail(
      String sourcePath, String docId, String fileType) async {
    if (fileType == 'image' || FileUtils.isImage(sourcePath)) {
      final bytes = await File(sourcePath).readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      final thumbnail = img.copyResize(original,
          width: AppConstants.thumbnailSize,
          interpolation: img.Interpolation.linear);
      final thumbBytes = Uint8List.fromList(img.encodeJpg(thumbnail, quality: 80));
      return _storage.storeThumbnail(thumbBytes, '${docId}_thumb.jpg');
    }
    return null;
  }
}
