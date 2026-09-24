import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

/// AES-256-GCM encryption/decryption for document files.
///
/// The encryption key is generated once at first setup and stored in
/// `flutter_secure_storage` (backed by Android Keystore). Each encrypted
/// payload starts with a 12-byte IV followed by the ciphertext.
class EncryptionUtils {
  EncryptionUtils._();

  static const int _ivLength = 12; // 96 bits for GCM
  static const int _keyLength = 32; // 256 bits

  /// Generate a random 256-bit key encoded as base64.
  static String generateKey() {
    final random = Random.secure();
    final keyBytes = Uint8List(_keyLength);
    for (var i = 0; i < _keyLength; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    return base64Encode(keyBytes);
  }

  /// Encrypt [data] using AES-256-GCM with [base64Key].
  ///
  /// Returns IV (12 bytes) prepended to the ciphertext.
  static Uint8List encrypt(Uint8List data, String base64Key) {
    final keyBytes = base64Decode(base64Key);
    final key = enc.Key(Uint8List.fromList(keyBytes));

    final random = Random.secure();
    final ivBytes = Uint8List(_ivLength);
    for (var i = 0; i < _ivLength; i++) {
      ivBytes[i] = random.nextInt(256);
    }
    final iv = enc.IV(ivBytes);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(data, iv: iv);

    // Prepend IV to ciphertext
    final result = Uint8List(ivBytes.length + encrypted.bytes.length);
    result.setAll(0, ivBytes);
    result.setAll(ivBytes.length, encrypted.bytes);
    return result;
  }

  /// Decrypt [data] (IV + ciphertext) using AES-256-GCM with [base64Key].
  static Uint8List decrypt(Uint8List data, String base64Key) {
    final keyBytes = base64Decode(base64Key);
    final key = enc.Key(Uint8List.fromList(keyBytes));

    final ivBytes = data.sublist(0, _ivLength);
    final iv = enc.IV(Uint8List.fromList(ivBytes));
    final ciphertext = data.sublist(_ivLength);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = enc.Encrypted(Uint8List.fromList(ciphertext));
    final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
    return Uint8List.fromList(decrypted);
  }

  /// Generate a random salt as base64 for PIN hashing.
  static String generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      salt[i] = random.nextInt(256);
    }
    return base64Encode(salt);
  }
}
