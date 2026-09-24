import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:my_doc_wallet/core/utils/encryption_utils.dart';
import 'package:my_doc_wallet/core/utils/file_utils.dart';

/// Manages encrypted file storage in the app's private directory.
///
/// Files are encrypted with AES-256-GCM before writing to disk.
/// The encryption key must be provided by [SecurityService] after
/// authentication.
class FileStorageService {
  String? _encryptionKey;
  String? _baseDir;

  static const String _docsFolder = 'encrypted_docs';
  static const String _thumbsFolder = 'thumbnails';
  static const String _tempFolder = 'temp_viewer';

  /// Set the encryption key (called after successful authentication).
  void setEncryptionKey(String key) => _encryptionKey = key;

  /// Clear the encryption key (called on lock).
  void clearEncryptionKey() => _encryptionKey = null;

  Future<String> get _basePath async {
    if (_baseDir != null) return _baseDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _baseDir = appDir.path;
    return _baseDir!;
  }

  Future<String> get _docsPath async {
    final base = await _basePath;
    final dir = p.join(base, _docsFolder);
    await FileUtils.ensureDir(dir);
    return dir;
  }

  Future<String> get _thumbsPath async {
    final base = await _basePath;
    final dir = p.join(base, _thumbsFolder);
    await FileUtils.ensureDir(dir);
    return dir;
  }

  Future<String> get _tempPath async {
    final base = await _basePath;
    final dir = p.join(base, _tempFolder);
    await FileUtils.ensureDir(dir);
    return dir;
  }

  /// Store a file, encrypting it. Returns the relative path.
  Future<String> storeFile(Uint8List data, String filename) async {
    final key = _encryptionKey;
    if (key == null) throw StateError('Encryption key not set');

    final docsDir = await _docsPath;
    final encrypted = EncryptionUtils.encrypt(data, key);
    final filePath = p.join(docsDir, filename);
    await File(filePath).writeAsBytes(encrypted);
    return p.join(_docsFolder, filename);
  }

  /// Store a thumbnail (encrypted).
  Future<String> storeThumbnail(Uint8List data, String filename) async {
    final key = _encryptionKey;
    if (key == null) throw StateError('Encryption key not set');

    final thumbDir = await _thumbsPath;
    final encrypted = EncryptionUtils.encrypt(data, key);
    final filePath = p.join(thumbDir, filename);
    await File(filePath).writeAsBytes(encrypted);
    return p.join(_thumbsFolder, filename);
  }

  /// Read and decrypt a file. Returns the raw bytes.
  Future<Uint8List> readFile(String relativePath) async {
    final key = _encryptionKey;
    if (key == null) throw StateError('Encryption key not set');

    final base = await _basePath;
    final filePath = p.join(base, relativePath);
    final encrypted = await File(filePath).readAsBytes();
    return EncryptionUtils.decrypt(encrypted, key);
  }

  /// Decrypt a file to a temporary location for viewing/sharing.
  /// Returns the temp file path.
  Future<String> decryptToTemp(String relativePath, String tempFilename) async {
    final data = await readFile(relativePath);
    final tempDir = await _tempPath;
    final tempFile = p.join(tempDir, tempFilename);
    await File(tempFile).writeAsBytes(data);
    return tempFile;
  }

  /// Delete an encrypted file.
  Future<void> deleteFile(String relativePath) async {
    final base = await _basePath;
    await FileUtils.deleteIfExists(p.join(base, relativePath));
  }

  /// Clear all temporary decrypted files.
  Future<void> clearTemp() async {
    final tempDir = await _tempPath;
    final dir = Directory(tempDir);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        await entity.delete();
      }
    }
  }

  /// Store a file from a source path (copies + encrypts).
  Future<String> storeFromPath(String sourcePath, String destFilename) async {
    final data = await File(sourcePath).readAsBytes();
    return storeFile(data, destFilename);
  }

  /// Get the absolute path for a relative path.
  Future<String> absolutePath(String relativePath) async {
    final base = await _basePath;
    return p.join(base, relativePath);
  }
}
