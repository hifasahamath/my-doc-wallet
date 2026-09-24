import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/core/utils/date_utils.dart';
import 'package:my_doc_wallet/data/models/document.dart';
import 'package:my_doc_wallet/providers/document_provider.dart';
import 'package:my_doc_wallet/services/file_storage_service.dart';
import 'package:my_doc_wallet/services/export_service.dart';

/// Screen displaying document details and viewer.
class DocumentDetailScreen extends StatefulWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  Document? _document;
  bool _isLoading = true;
  String? _tempFilePath;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    // Cleanup temp file when leaving screen
    if (_tempFilePath != null) {
      File(_tempFilePath!).delete().ignore();
    }
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() => _isLoading = true);
    final doc = await context.read<DocumentProvider>().getDocument(widget.documentId);
    
    if (doc != null && mounted) {
      // Decrypt to temp file for viewing
      try {
        final ext = doc.fileType == 'pdf' ? 'pdf' : 'jpg';
        _tempFilePath = await context.read<FileStorageService>().decryptToTemp(doc.filePath, 'temp_view_${doc.id}.$ext');
      } catch (e) {
        // Handle error
      }
    }
    
    if (mounted) {
      setState(() {
        _document = doc;
        _isLoading = false;
      });
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document?'),
        content: const Text('This will permanently delete this document and all its files from your device. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await context.read<DocumentProvider>().deleteDocument(widget.documentId);
              if (context.mounted) context.pop(); // Go back
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_document == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Document not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_document!.name, style: theme.textTheme.titleMedium),
        actions: [
          IconButton(
            icon: Icon(_document!.isFavorite ? Icons.star : Icons.star_border),
            color: _document!.isFavorite ? Colors.amber : null,
            onPressed: () async {
              await context.read<DocumentProvider>().toggleFavorite(_document!.id, !_document!.isFavorite);
              _loadDocument();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                context.push('/edit-document/${_document!.id}').then((_) => _loadDocument());
              } else if (value == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Viewer area
          Expanded(
            flex: 3,
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: _buildViewer(),
            ),
          ),
          
          // Details area
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoRow('Category', _document!.categoryName ?? 'Unknown'),
                if (_document!.documentNumber != null && _document!.documentNumber!.isNotEmpty)
                  _buildInfoRow('Document No.', _document!.documentNumber!),
                if (_document!.issueDate != null)
                  _buildInfoRow('Issue Date', AppDateUtils.formatDisplay(_document!.issueDate)),
                if (_document!.expiryDate != null)
                  _buildInfoRow('Expiry Date', AppDateUtils.formatDisplay(_document!.expiryDate), 
                    subtitle: AppDateUtils.expiryDescription(_document!.expiryDate)),
                if (_document!.notes != null && _document!.notes!.isNotEmpty)
                  _buildInfoRow('Notes', _document!.notes!),
                if (_document!.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      children: _document!.tags.map((t) => Chip(label: Text(t))).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_document != null) {
            final ext = _document!.fileType == 'pdf' ? '.pdf' : '.jpg';
            final displayName = '${_document!.name.replaceAll(' ', '_')}$ext';
            await context.read<ExportService>().shareDocument(_document!.filePath, displayName);
          }
        },
        child: const Icon(Icons.share),
      ),
    );
  }

  Widget _buildViewer() {
    if (_tempFilePath == null) {
      return const Center(child: Icon(Icons.error, size: 48, color: Colors.grey));
    }
    
    if (_document!.fileType == 'pdf') {
      // In a real app we'd use pdfrx or similar here. 
      // For now, placeholder indicating PDF is ready
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('PDF Ready for Viewing'),
          ],
        ),
      );
    } else {
      return InteractiveViewer(
        child: Image.file(
          File(_tempFilePath!),
          fit: BoxFit.contain,
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value, {String? subtitle}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
          if (subtitle != null)
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
        ],
      ),
    );
  }
}
