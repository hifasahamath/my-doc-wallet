import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/core/utils/date_utils.dart';
import 'package:my_doc_wallet/data/models/document.dart';
import 'package:my_doc_wallet/services/file_storage_service.dart';
import 'package:my_doc_wallet/widgets/status_badge.dart';

/// A list tile card for a document, with thumbnail, status badge, and subtitle.
class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              _buildThumbnail(context),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (document.expiryStatus != ExpiryStatus.none)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child:
                                StatusBadge(status: document.expiryStatus, compact: true),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document.categoryName ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (document.expiryDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        AppDateUtils.expiryDescription(document.expiryDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _expiryColor(document.expiryStatus),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Favorite button
              IconButton(
                icon: Icon(
                  document.isFavorite ? Icons.star : Icons.star_border,
                  color: document.isFavorite
                      ? Colors.amber
                      : theme.colorScheme.onSurfaceVariant.withAlpha(120),
                  size: 22,
                ),
                onPressed: onFavoriteTap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final theme = Theme.of(context);
    const size = 52.0;

    if (document.thumbnailPath == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          document.fileType == 'pdf'
              ? Icons.picture_as_pdf
              : Icons.image,
          color: theme.colorScheme.onSurfaceVariant,
          size: 24,
        ),
      );
    }

    return FutureBuilder<Uint8List>(
      future: context.read<FileStorageService>().readFile(document.thumbnailPath!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              snapshot.data!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        }
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  Color _expiryColor(ExpiryStatus status) {
    return switch (status) {
      ExpiryStatus.expired => const Color(0xFFD32F2F),
      ExpiryStatus.expiringSoon => const Color(0xFFF57C00),
      _ => const Color(0xFF388E3C),
    };
  }
}
