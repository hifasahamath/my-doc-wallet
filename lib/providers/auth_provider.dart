import 'package:flutter/foundation.dart';

import 'package:my_doc_wallet/services/security_service.dart';
import 'package:my_doc_wallet/services/file_storage_service.dart';

/// Manages the app lock/unlock state and authentication flow.
class AuthProvider extends ChangeNotifier {
  final SecurityService _security;
  final FileStorageService _storage;

  bool _isSetupComplete = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;

  AuthProvider(this._security, this._storage);

  bool get isLocked => _security.isLocked;
  bool get isSetupComplete => _isSetupComplete;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;

  Future<void> initialize() async {
    _isSetupComplete = await _security.isSetupComplete();
    _isBiometricAvailable = await _security.isBiometricAvailable();
    _isBiometricEnabled = await _security.isBiometricEnabled();
    notifyListeners();
  }

  Future<void> setupPin(String pin) async {
    await _security.setupPin(pin);
    _storage.setEncryptionKey(_security.encryptionKey!);
    _isSetupComplete = true;
    notifyListeners();
  }

  Future<void> changePin(String oldPin, String newPin) async {
    await _security.changePin(oldPin, newPin);
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final result = await _security.verifyPin(pin);
    if (result && _security.encryptionKey != null) {
      _storage.setEncryptionKey(_security.encryptionKey!);
    }
    notifyListeners();
    return result;
  }

  Future<bool> authenticateWithBiometric() async {
    final result = await _security.authenticateWithBiometric();
    if (result && _security.encryptionKey != null) {
      _storage.setEncryptionKey(_security.encryptionKey!);
    }
    notifyListeners();
    return result;
  }

  void lock() {
    _security.lock();
    _storage.clearEncryptionKey();
    _storage.clearTemp();
    notifyListeners();
  }

  void recordActivity() {
    _security.recordActivity();
  }

  Future<bool> shouldAutoLock() => _security.shouldAutoLock();

  Future<void> toggleBiometric(bool enabled) async {
    await _security.setBiometricEnabled(enabled);
    _isBiometricEnabled = enabled;
    notifyListeners();
  }
}
