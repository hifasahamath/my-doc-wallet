import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/providers/document_provider.dart';
import 'package:my_doc_wallet/providers/category_provider.dart';
import 'package:my_doc_wallet/widgets/document_grid_card.dart';
import 'package:my_doc_wallet/widgets/empty_state.dart';

/// Full document list with pull-to-refresh, two-column grid, and multi-select.
class DocumentsListScreen extends StatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  State<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends State<DocumentsListScreen> {
  final Set<String> _selectedIds = {};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadDocuments();
    });
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final theme = Theme.of(context);

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
              title: Text('All Documents',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              actions: [
                PopupMenuButton<DocumentSortOption>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort Documents',
                  initialValue: provider.sortOption,
                  onSelected: (option) => provider.setSortOption(option),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: DocumentSortOption.recentlyUpdated, child: Text('Recently Added')),
                    PopupMenuItem(value: DocumentSortOption.nameAsc, child: Text('Name (A-Z)')),
                    PopupMenuItem(value: DocumentSortOption.expiryDateAsc, child: Text('Expiry Date')),
                    PopupMenuItem(value: DocumentSortOption.categoryName, child: Text('Category')),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.push('/search'),
                ),
              ],
            ),
      body: provider.isLoading && provider.documents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.documents.isEmpty
              ? const EmptyState(
                  icon: Icons.description_outlined,
                  title: 'No documents yet',
                  subtitle: 'Import a file or scan a document to get started',
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadDocuments(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: provider.documents.length,
                    itemBuilder: (context, index) {
                      final doc = provider.documents[index];
                      final isSelected = _selectedIds.contains(doc.id);

                      return DocumentGridCard(
                        document: doc,
                        isSelected: isSelected,
                        isSelectionMode: _isSelectionMode,
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(doc.id);
                          } else {
                            context.push('/document/${doc.id}');
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _toggleSelection(doc.id);
                          }
                        },
                        onFavoriteTap: () =>
                            provider.toggleFavorite(doc.id, !doc.isFavorite),
                      );
                    },
                  ),
                ),
    );
  }
}
