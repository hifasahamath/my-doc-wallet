/// App-wide constants for MyDoc Wallet.
class AppConstants {
  AppConstants._();

  static const String appName = 'MyDoc Wallet';

  // Security
  static const int pinLength = 4;
  static const int defaultAutoLockSeconds = 60;
  static const String encryptionKeyStorageKey = 'mydocwallet_encryption_key';
  static const String pinHashStorageKey = 'mydocwallet_pin_hash';
  static const String pinSaltStorageKey = 'mydocwallet_pin_salt';
  static const String biometricEnabledKey = 'mydocwallet_biometric_enabled';
  static const String autoLockSecondsKey = 'mydocwallet_auto_lock_seconds';
  static const String isSetupCompleteKey = 'mydocwallet_setup_complete';
  static const String themeModeKey = 'mydocwallet_theme_mode';

  // Expiry thresholds (days)
  static const int expiryWarning90 = 90;
  static const int expiryWarning30 = 30;
  static const int expiryWarning7 = 7;
  static const int expiryWarning1 = 1;

  // File limits
  static const int maxFileSizeMB = 50;
  static const int thumbnailSize = 300;

  // Notification channel
  static const String notificationChannelId = 'mydocwallet_expiry';
  static const String notificationChannelName = 'Document Expiry Reminders';
  static const String notificationChannelDesc =
      'Notifications for documents approaching their expiry date';

  // Database
  static const String databaseName = 'mydocwallet.db';
  static const int databaseVersion = 2;

  // Category order persistence key
  static const String categoryOrderKey = 'mydocwallet_category_order';

  // Auto-lock options (seconds) — 0 = immediately, -1 = never
  static const Map<int, String> autoLockOptions = {
    0: 'Immediately',
    30: '30 seconds',
    60: '1 minute',
    300: '5 minutes',
    900: '15 minutes',
    -1: 'Never',
  };

  // ─────────────────────────────────────────────────────────────────────
  // Developer information
  //
  // To update your personal information, edit ONLY the values below.
  // The entire About screen references these constants, so changing a
  // value here automatically updates every place it is displayed.
  // ─────────────────────────────────────────────────────────────────────

  /// Full name displayed in the About screen.
  static const String developerName = 'Hifas Ahamath';

  /// Job title / role.
  static const String developerRole = 'Software Engineer';

  /// GitHub username (displayed as @handle).
  static const String developerGithub = '@hifasahamath';

  /// Full GitHub profile URL (opened when tapped).
  static const String developerGithubUrl = 'https://github.com/hifasahamath';

  /// Phone number displayed next to the WhatsApp icon.
  static const String developerWhatsApp = '+94 77 560 5161';

  /// WhatsApp deep-link URL (opened when tapped).
  static const String developerWhatsAppUrl = 'https://wa.me/94775605161';

  /// Website text displayed next to the globe icon.
  static const String developerWebsite = 'www.hifasahamath.com';

  /// Full website URL (opened when tapped).
  static const String developerWebsiteUrl = 'https://www.hifasahamath.com';
}
