import 'package:intl/intl.dart';

/// Helpers for expiry-date calculations.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat dateTimeDisplayFormat = DateFormat('dd MMM yyyy, h:mm a');
  static final DateFormat isoFormat = DateFormat('yyyy-MM-dd');

  /// Days until [expiryDate]. Negative if expired.
  static int daysUntilExpiry(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  /// Classify the expiry status of a document.
  static ExpiryStatus getExpiryStatus(DateTime? expiryDate) {
    if (expiryDate == null) return ExpiryStatus.none;
    final days = daysUntilExpiry(expiryDate);
    if (days < 0) return ExpiryStatus.expired;
    if (days <= 30) return ExpiryStatus.expiringSoon;
    return ExpiryStatus.active;
  }

  /// Human-readable relative expiry string.
  static String expiryDescription(DateTime? expiryDate) {
    if (expiryDate == null) return 'No expiry date';
    final days = daysUntilExpiry(expiryDate);
    if (days < 0) {
      return 'Expired ${-days} day${-days == 1 ? '' : 's'} ago';
    }
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 30) return 'Expires in $days days';
    return 'Expires on ${displayFormat.format(expiryDate)}';
  }

  /// Format a [DateTime] for display, or return a fallback.
  static String formatDisplay(DateTime? date, {String fallback = '—'}) {
    if (date == null) return fallback;
    return displayFormat.format(date);
  }

  /// Format a [DateTime] with time for display, or return a fallback.
  static String formatDateTimeDisplay(DateTime? date, {String fallback = '—'}) {
    if (date == null) return fallback;
    return dateTimeDisplayFormat.format(date);
  }

  /// Format a [DateTime] as ISO 8601 date string for storage.
  static String? formatIso(DateTime? date) {
    if (date == null) return null;
    return isoFormat.format(date);
  }

  /// Parse an ISO 8601 date string.
  static DateTime? parseIso(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

/// Classification of a document's expiry state.
enum ExpiryStatus {
  active,
  expiringSoon,
  expired,
  none,
}
