import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/data/models/document.dart';
import 'package:my_doc_wallet/providers/document_provider.dart';
import 'package:my_doc_wallet/providers/category_provider.dart';
import 'package:my_doc_wallet/widgets/document_grid_card.dart';
import 'package:my_doc_wallet/widgets/empty_state.dart';

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
  
  final Set<String> _selectedIds = {};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
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
            ...categories.map((c) => ListTile(
              leading: Icon(Icons.folder, color: Color(c.color)),
              title: Text(c.name),
              onTap: () => Navigator.pop(context, c.id),
            )),
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
    final ctrl = TextEditingController(text: widget.categoryName);
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
      // In a real app we'd update the UI title, here it's static in the state widget.
      // Easiest is to pop back and let the list refresh.
      if (mounted) context.pop();
    }
  }

  Future<void> _deleteCategory() async {
    final categories = context.read<CategoryProvider>().categories.where((c) => c.id != widget.categoryId).toList();
    
    String? moveToId;
    if (_documents.isNotEmpty) {
      moveToId = await showDialog<String>(
        context: context,
        builder: (context) {
          String? selectedId = categories.isNotEmpty ? categories.first.id : null;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Delete Category'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This category contains documents. Please select a category to move them to before deleting:'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedId,
                      items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (val) => setState(() => selectedId = val),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                    onPressed: () => Navigator.pop(context, selectedId),
                    child: const Text('Move & Delete'),
                  ),
                ],
              );
            }
          );
        },
      );
      
      if (moveToId == null) return; // User cancelled
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Category'),
          content: const Text('Are you sure you want to delete this empty category?'),
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
    }

    if (mounted) {
      await context.read<CategoryProvider>().deleteCategory(widget.categoryId, moveDocumentsTo: moveToId);
      if (mounted) context.pop();
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: const Text('Scan Document'),
              subtitle: const Text('Scan and save into this category'),
              onTap: () {
                Navigator.pop(context);
                context.push('/add-document-scan', extra: {'categoryId': widget.categoryId});
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Import File'),
              subtitle: const Text('Import PDF/image into this category'),
              onTap: () {
                Navigator.pop(context);
                context.push('/add-document-file', extra: {'categoryId': widget.categoryId});
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Check if category is a default/built-in category (usually they have isCustom = false)
    final catProvider = context.watch<CategoryProvider>();
    final isCustom = catProvider.categories.any((c) => c.id == widget.categoryId && c.isCustom);
    
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
              title: Text(widget.categoryName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                if (isCustom)
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
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
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
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
