import 'package:flutter/material.dart';

class ImportOptionsWidget extends StatelessWidget {
  final String? categoryId;
  final String? categoryName;
  final VoidCallback onScan;
  final VoidCallback onImport;

  const ImportOptionsWidget({
    super.key,
    this.categoryId,
    this.categoryName,
    required this.onScan,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final scanSubtitle = categoryName != null 
        ? 'Scan and save into $categoryName' 
        : 'Use camera to scan physical documents';
    final importSubtitle = categoryName != null 
        ? 'Import PDF/image into $categoryName' 
        : 'Import PDF or image from your device';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: const Icon(Icons.document_scanner_outlined, size: 32),
              title: const Text('Scan Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              subtitle: Text(scanSubtitle, style: const TextStyle(fontSize: 14)),
              onTap: onScan,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: const Icon(Icons.file_upload_outlined, size: 32),
              title: const Text('Import File', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              subtitle: Text(importSubtitle, style: const TextStyle(fontSize: 14)),
              onTap: onImport,
            ),
          ],
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    String? categoryId,
    String? categoryName,
    required VoidCallback onScan,
    required VoidCallback onImport,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ImportOptionsWidget(
        categoryId: categoryId,
        categoryName: categoryName,
        onScan: () {
          Navigator.pop(ctx);
          onScan();
        },
        onImport: () {
          Navigator.pop(ctx);
          onImport();
        },
      ),
    );
  }
}
