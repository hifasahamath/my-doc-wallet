import 'dart:io';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:my_doc_wallet/services/file_storage_service.dart';

/// Handles document export, sharing, and redaction.
class ExportService {
  final FileStorageService _storage;

  ExportService(this._storage);

  /// Export a document to a shareable temp file and open the share sheet.
  Future<void> shareDocument(String relativePath, String displayName) async {
    final tempPath = await _storage.decryptToTemp(relativePath, displayName);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(tempPath)], text: displayName),
    );
  }

  /// Export with redaction: draw black rectangles over specified regions,
  /// then flatten to an image-based PDF so redaction is permanent.
  Future<void> shareRedactedDocument({
    required String relativePath,
    required String displayName,
    required List<RedactionRect> redactions,
  }) async {
    final data = await _storage.readFile(relativePath);
    // For image files: apply redaction directly
    final tempDir = await getTemporaryDirectory();
    final outputPath = p.join(tempDir.path, 'redacted_$displayName');

    // Decode image, apply black rectangles, re-encode
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());

    for (final rect in redactions) {
      canvas.drawRect(
        ui.Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height),
        ui.Paint()..color = const ui.Color(0xFF000000),
      );
    }

    final picture = recorder.endRecording();
    final redactedImage =
        await picture.toImage(image.width, image.height);
    final byteData =
        await redactedImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to render redacted image');

    final pngBytes = byteData.buffer.asUint8List();

    // If we want PDF output:
    if (displayName.toLowerCase().endsWith('.pdf')) {
      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) =>
            pw.Center(child: pw.Image(pw.MemoryImage(pngBytes), fit: pw.BoxFit.contain)),
      ));
      await File(outputPath).writeAsBytes(await pdf.save());
    } else {
      await File(outputPath).writeAsBytes(pngBytes);
    }

    await SharePlus.instance.share(
      ShareParams(files: [XFile(outputPath)], text: displayName),
    );
  }

  /// Clean up temp export files.
  Future<void> cleanupTemp() async {
    await _storage.clearTemp();
  }
}

/// A rectangular region to redact (in image coordinates).
class RedactionRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const RedactionRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
