import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'package:my_doc_wallet/core/constants/app_constants.dart';
import 'package:my_doc_wallet/core/utils/encryption_utils.dart';

/// Manages PIN authentication, biometric auth, encryption key, and lock state.
class SecurityService {
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  bool _isLocked = true;
  String? _encryptionKey;
  DateTime? _lastActivity;

  bool get isLocked => _isLocked;
  String? get encryptionKey => _encryptionKey;

  // ── Setup ──────────────────────────────────────────────────────────────

  Future<bool> isSetupComplete() async {
    final value = await _secureStorage.read(key: AppConstants.isSetupCompleteKey);
    return value == 'true';
  }

  Future<void> setupPin(String pin) async {
    final salt = EncryptionUtils.generateSalt();
    final hash = _hashPin(pin, salt);
    final encKey = EncryptionUtils.generateKey();

    await _secureStorage.write(key: AppConstants.pinSaltStorageKey, value: salt);
    await _secureStorage.write(key: AppConstants.pinHashStorageKey, value: hash);
    await _secureStorage.write(key: AppConstants.encryptionKeyStorageKey, value: encKey);
    await _secureStorage.write(key: AppConstants.isSetupCompleteKey, value: 'true');

    _encryptionKey = encKey;
    _isLocked = false;
    _lastActivity = DateTime.now();
  }

  // ── PIN auth ───────────────────────────────────────────────────────────

  Future<bool> verifyPin(String pin) async {
    final salt = await _secureStorage.read(key: AppConstants.pinSaltStorageKey);
    final storedHash = await _secureStorage.read(key: AppConstants.pinHashStorageKey);
    if (salt == null || storedHash == null) return false;

    final hash = _hashPin(pin, salt);
    if (hash == storedHash) {
      await _unlock();
      return true;
    }
    return false;
  }

  Future<void> changePin(String oldPin, String newPin) async {
    if (!await verifyPin(oldPin)) throw Exception('Invalid current PIN');
    final salt = EncryptionUtils.generateSalt();
    final hash = _hashPin(newPin, salt);
    await _secureStorage.write(key: AppConstants.pinSaltStorageKey, value: salt);
    await _secureStorage.write(key: AppConstants.pinHashStorageKey, value: hash);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  // ── Biometric auth ─────────────────────────────────────────────────────

  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: AppConstants.biometricEnabledKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: AppConstants.biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access MyDoc Wallet',
      );
      if (authenticated) {
        await _unlock();
      }
      return authenticated;
    } catch (e) {
      return false;
    }
  }

  // ── Lock / Unlock ──────────────────────────────────────────────────────

  Future<void> _unlock() async {
    _encryptionKey =
        await _secureStorage.read(key: AppConstants.encryptionKeyStorageKey);
    _isLocked = false;
    _lastActivity = DateTime.now();
  }

  void lock() {
    _isLocked = true;
    _encryptionKey = null;
    _lastActivity = null;
  }

  void recordActivity() {
    _lastActivity = DateTime.now();
  }

  /// Check whether the auto-lock timeout has elapsed.
  Future<bool> shouldAutoLock() async {
    if (_isLocked) return false;
    final timeout = await getAutoLockSeconds();
    if (timeout < 0) return false; // "Never"
    if (_lastActivity == null) return true;
    final elapsed = DateTime.now().difference(_lastActivity!).inSeconds;
    return elapsed >= timeout;
  }

  Future<int> getAutoLockSeconds() async {
    final value = await _secureStorage.read(key: AppConstants.autoLockSecondsKey);
    return value != null ? int.tryParse(value) ?? AppConstants.defaultAutoLockSeconds : AppConstants.defaultAutoLockSeconds;
  }

  Future<void> setAutoLockSeconds(int seconds) async {
    await _secureStorage.write(
      key: AppConstants.autoLockSecondsKey,
      value: seconds.toString(),
    );
  }

  // ── Theme ──────────────────────────────────────────────────────────────

  Future<String> getThemeMode() async {
    return await _secureStorage.read(key: AppConstants.themeModeKey) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    await _secureStorage.write(key: AppConstants.themeModeKey, value: mode);
  }
}
