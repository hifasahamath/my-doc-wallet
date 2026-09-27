import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/core/utils/file_utils.dart';
import 'package:my_doc_wallet/data/models/document.dart';
import 'package:my_doc_wallet/providers/document_provider.dart';
import 'package:my_doc_wallet/providers/category_provider.dart';
import 'package:my_doc_wallet/providers/dashboard_provider.dart';
import 'package:my_doc_wallet/services/import_service.dart';
import 'package:my_doc_wallet/widgets/document_grid_card.dart';
import 'package:my_doc_wallet/widgets/empty_state.dart';
import 'package:my_doc_wallet/widgets/import_metadata_dialog.dart';
import 'package:my_doc_wallet/widgets/import_options_widget.dart';

/// Screen listing documents for a specific category.
class CategoryDocumentsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryDocumentsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryDocumentsScreen> createState() => _CategoryDocumentsScreenState();
}

class _CategoryDocumentsScreenState extends State<CategoryDocumentsScreen> {
  List<Document> _documents = [];
  bool _isLoading = true;
  late String _displayName;
  
  final Set<String> _selectedIds = {};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _displayName = widget.categoryName;
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final docs = await context.read<DocumentProvider>().getByCategory(widget.categoryId);
    if (mounted) {
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Documents?'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} document(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<DocumentProvider>().deleteDocuments(_selectedIds.toList());
      _clearSelection();
      _loadDocuments();
    }
  }

  Future<void> _moveSelected() async {
    final categories = context.read<CategoryProvider>().categories;
    final categoryId = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Move to Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final c = categories[index];
                  return ListTile(
                    leading: Icon(Icons.folder, color: Color(c.color)),
                    title: Text(c.name),
                    onTap: () => Navigator.pop(context, c.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (categoryId != null && mounted) {
      await context.read<DocumentProvider>().moveMultipleToCategory(_selectedIds.toList(), categoryId);
      _clearSelection();
      _loadDocuments();
    }
  }

  Future<void> _renameCategory() async {
    final ctrl = TextEditingController(text: _displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && mounted) {
      final provider = context.read<CategoryProvider>();
      final category = provider.categories.firstWhere((c) => c.id == widget.categoryId);
      await provider.updateCategory(category.copyWith(name: newName));
      setState(() => _displayName = newName);
    }
  }

  Future<void> _deleteCategory() async {
    final categories = context.read<CategoryProvider>().categories.where((c) => c.id != widget.categoryId).toList();
    
    if (_documents.isNotEmpty) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Delete "$_displayName"?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This category contains ${_documents.length} document(s).'),
                const SizedBox(height: 8),
                const Text('What would you like to do with these documents?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              OutlinedButton(
                onPressed: () {
                  // Move to "Other" category if it exists, or the first available
                  final otherCat = categories.firstWhere(
                    (c) => c.id == 'uncategorized' || c.name.toLowerCase() == 'uncategorized',
                    orElse: () => categories.first,
                  );
                  Navigator.pop(context, otherCat.id);
                },
                child: const Text('Move to Other'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => Navigator.pop(context, '__delete_all__'),
                child: const Text('Delete Category and Documents'),
              ),
            ],
          );
        },
      );
      
      if (result == null || !mounted) return;

      if (result == '__delete_all__') {
        // Delete all documents first, then the category
        if (!mounted) return;
        await context.read<DocumentProvider>().deleteDocuments(
          _documents.map((d) => d.id).toList(),
        );
        if (!mounted) return;
        await context.read<CategoryProvider>().deleteCategory(widget.categoryId);
      } else {
        // Move docs to selected category, then delete
        if (!mounted) return;
        await context.read<CategoryProvider>().deleteCategory(widget.categoryId, moveDocumentsTo: result);
      }
      if (mounted) context.pop();
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete "$_displayName"?'),
          content: const Text('This category is empty and will be deleted.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      if (mounted) {
        await context.read<CategoryProvider>().deleteCategory(widget.categoryId);
        if (mounted) context.pop();
      }
    }
  }

  void _showAddOptions(BuildContext context) {
    ImportOptionsWidget.show(
      context,
      categoryId: widget.categoryId,
      categoryName: _displayName,
      onScan: () => _handleScan(context),
      onImport: () => _handleImport(context),
    );
  }

  /// Import a file directly into this category — no form.
  Future<void> _handleImport(BuildContext context) async {
    final importService = context.read<ImportService>();
    final docProvider = context.read<DocumentProvider>();

    try {
      final path = await importService.pickFile();
      if (path == null) return; // User cancelled

      if (!context.mounted) return;

      final generatedTitle = FileUtils.titleFromFilename(path);

      final metadata = await ImportMetadataDialog.show(
        context,
        initialTitle: generatedTitle,
        initialCategoryId: widget.categoryId,
      );
      if (metadata == null) return; // User cancelled

      if (!context.mounted) return;

      final title = metadata['title'] as String? ?? generatedTitle;
      final selectedCategory = metadata['categoryId'] as String? ?? 'uncategorized';
      final expiryDate = metadata['expiryDate'] as DateTime?;

      _showLoading(context, 'Importing document...');

      final newDoc = await docProvider.importFile(
        sourcePath: path,
        name: title,
        categoryId: selectedCategory,
      );

      if (expiryDate != null) {
        await docProvider.updateDocument(newDoc.copyWith(expiryDate: expiryDate));
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
        _loadDocuments();
        context.read<DashboardProvider>().loadDashboard();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$title" imported into $_displayName')),
        );
      }
    } on ImportException catch (e) {
      if (context.mounted) {
        try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
        if (e.isPermanentlyDenied) {
          _showPermissionDeniedDialog(context, e.message);
        } else {
          _showError(context, e.message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
        _showError(context, 'Failed to import document: $e');
      }
    }
  }

  /// Scan a document directly into this category — no form.
  Future<void> _handleScan(BuildContext context) async {
    final importService = context.read<ImportService>();
    final docProvider = context.read<DocumentProvider>();

    try {
      final paths = await importService.scanDocuments();
      if (paths == null || paths.isEmpty) return; // User cancelled

      if (!context.mounted) return;

      final metadata = await ImportMetadataDialog.show(
        context,
        initialTitle: 'Scanned Document',
        initialCategoryId: widget.categoryId,
      );
      if (metadata == null) return; // User cancelled

      if (!context.mounted) return;

      final title = metadata['title'] as String? ?? 'Scanned Document';
      final selectedCategory = metadata['categoryId'] as String? ?? 'uncategorized';
      final expiryDate = metadata['expiryDate'] as DateTime?;

      _showLoading(context, 'Saving scanned document...');

      final newDoc = await docProvider.createFromScan(
        imagePaths: paths,
        name: title,
        categoryId: selectedCategory,
      );

      if (expiryDate != null) {
        await docProvider.updateDocument(newDoc.copyWith(expiryDate: expiryDate));
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
        _loadDocuments();
        context.read<DashboardProvider>().loadDashboard();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanned document saved to $_displayName')),
        );
      }
    } on ImportException catch (e) {
      if (context.mounted) {
        if (e.isPermanentlyDenied) {
          _showPermissionDeniedDialog(context, e.message);
        } else {
          _showError(context, e.message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
        _showError(context, 'Failed to scan document: $e');
      }
    }
  }

  void _showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 24),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showPermissionDeniedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DocumentProvider>();

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text('${_selectedIds.length} Selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.drive_file_move_outline),
                  tooltip: 'Move',
                  onPressed: _moveSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: _deleteSelected,
                ),
              ],
            )
          : AppBar(
              title: Text(_displayName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              actions: [
                PopupMenuButton<DocumentSortOption>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort Documents',
                  initialValue: provider.sortOption,
                  onSelected: (option) {
                    provider.setSortOption(option);
                    _loadDocuments();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: DocumentSortOption.recentlyUpdated, child: Text('Recently Added')),
                    PopupMenuItem(value: DocumentSortOption.nameAsc, child: Text('Name (A-Z)')),
                    PopupMenuItem(value: DocumentSortOption.expiryDateAsc, child: Text('Expiry Date')),
                  ],
                ),
                if (widget.categoryId != 'uncategorized')
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'rename') _renameCategory();
                      if (val == 'delete') _deleteCategory();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                      ),
                    ],
                  ),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? EmptyState(
                  icon: Icons.folder_open,
                  title: 'No documents',
                  subtitle: 'This category is empty.',
                  action: FilledButton.icon(
                    onPressed: () => _showAddOptions(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Document'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);
                      final aspectRatio = width < 340 ? 0.75 : 0.8;
                      return GridView.builder(
                        padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      final isSelected = _selectedIds.contains(doc.id);
                      return DocumentGridCard(
                        document: doc,
                        isSelected: isSelected,
                        isSelectionMode: _isSelectionMode,
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(doc.id);
                          } else {
                            context.push('/document/${doc.id}').then((_) => _loadDocuments());
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _toggleSelection(doc.id);
                          }
                        },
                        onFavoriteTap: () async {
                          await context.read<DocumentProvider>().toggleFavorite(doc.id, !doc.isFavorite);
                          _loadDocuments();
                        },
                      );
                    },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
