import 'package:flutter/material.dart';

import 'package:my_doc_wallet/core/theme/app_theme.dart';
import 'package:my_doc_wallet/core/utils/date_utils.dart';

/// A colored badge indicating document expiry status.
class StatusBadge extends StatelessWidget {
  final ExpiryStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (status == ExpiryStatus.none) return const SizedBox.shrink();

    final (label, color) = switch (status) {
      ExpiryStatus.active => ('Active', AppTheme.activeColor),
      ExpiryStatus.expiringSoon => ('Expiring', AppTheme.expiringColor),
      ExpiryStatus.expired => ('Expired', AppTheme.expiredColor),
      ExpiryStatus.none => ('', Colors.transparent),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
