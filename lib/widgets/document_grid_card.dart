import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/core/utils/date_utils.dart';
import 'package:my_doc_wallet/data/models/document.dart';
import 'package:my_doc_wallet/services/file_storage_service.dart';
import 'package:my_doc_wallet/widgets/status_badge.dart';

/// A grid card for a document.
class DocumentGridCard extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteTap;
  final bool isSelected;
  final bool isSelectionMode;

  const DocumentGridCard({
    super.key,
    required this.document,
    this.onTap,
    this.onLongPress,
    this.onFavoriteTap,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      elevation: isSelected ? 4 : 1,
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail area
                Expanded(
                  flex: 3,
                  child: Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: _buildThumbnail(context),
                  ),
                ),
                // Text area
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          document.categoryName ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        if (document.expiryStatus != ExpiryStatus.none)
                          StatusBadge(status: document.expiryStatus, compact: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Selection overlay / checkbox
          if (isSelectionMode)
            Positioned(
              top: 4,
              left: 4,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onTap?.call(),
                shape: const CircleBorder(),
              ),
            ),
            
          // Favorite overlay
          if (!isSelectionMode)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(
                  document.isFavorite ? Icons.star : Icons.star_border,
                  color: document.isFavorite
                      ? Colors.amber
                      : theme.colorScheme.onSurfaceVariant.withAlpha(150),
                ),
                onPressed: onFavoriteTap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final theme = Theme.of(context);

    if (document.thumbnailPath == null) {
      return Center(
        child: Icon(
          document.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
          color: theme.colorScheme.onSurfaceVariant,
          size: 40,
        ),
      );
    }

    return FutureBuilder<Uint8List>(
      future: context.read<FileStorageService>().readFile(document.thumbnailPath!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        }
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }
}
