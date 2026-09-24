import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

/// Helpers for working with local files.
class FileUtils {
  FileUtils._();

  /// Human-readable file size string.
  static String formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final i = (log(bytes) / log(1024)).floor().clamp(0, suffixes.length - 1);
    final size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  /// File extension without the leading dot, lowercased.
  static String extension(String path) {
    return p.extension(path).replaceFirst('.', '').toLowerCase();
  }

  /// Whether [path] points to a PDF file.
  static bool isPdf(String path) => extension(path) == 'pdf';

  /// Whether [path] points to an image file.
  static bool isImage(String path) {
    const imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'};
    return imageExtensions.contains(extension(path));
  }

  /// Delete a file if it exists, swallowing errors.
  static Future<void> deleteIfExists(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Ensure a directory exists.
  static Future<Directory> ensureDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Generate a human-readable title from a filename.
  ///
  /// Examples:
  /// - `passport_2026.pdf` → `Passport 2026`
  /// - `Driving_License.jpg` → `Driving License`
  /// - `my-report (final).png` → `My Report Final`
  static String titleFromFilename(String filePath) {
    // Get basename without extension
    final basename = p.basenameWithoutExtension(filePath);

    // Replace underscores, dashes with spaces
    var title = basename.replaceAll(RegExp(r'[_\-]+'), ' ');

    // Remove parentheses but keep content
    title = title.replaceAll(RegExp(r'[()]'), '');

    // Remove multiple consecutive spaces
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Capitalize first letter of each word
    if (title.isEmpty) return 'Untitled Document';
    return title
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}
