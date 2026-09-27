import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/data/models/document.dart';
import 'package:my_doc_wallet/providers/document_provider.dart';
import 'package:my_doc_wallet/providers/dashboard_provider.dart';
import 'package:my_doc_wallet/widgets/document_grid_card.dart';
import 'package:my_doc_wallet/widgets/empty_state.dart';

class StatusDocumentsScreen extends StatefulWidget {
  final String status;

  const StatusDocumentsScreen({super.key, required this.status});

  @override
  State<StatusDocumentsScreen> createState() => _StatusDocumentsScreenState();
}

class _StatusDocumentsScreenState extends State<StatusDocumentsScreen> {
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
    final provider = context.read<DocumentProvider>();
    List<Document> docs = [];
    
    switch (widget.status) {
      case 'total':
        docs = await provider.getAllDocuments();
        break;
      case 'active':
        docs = await provider.getActiveDocuments();
        break;
      case 'expiring_soon':
        docs = await provider.getExpiringSoonDocuments(30);
        break;
      case 'expired':
        docs = await provider.getExpiredDocuments();
        break;
      default:
        docs = [];
    }

    if (mounted) {
      setState(() {
        _documents = docs;
        _isLoading = false;
        // Clean up selection if documents were deleted elsewhere
        _selectedIds.removeWhere((id) => !_documents.any((d) => d.id == id));
      });
      // Also refresh dashboard to keep counts synced
      context.read<DashboardProvider>().loadDashboard();
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
    setState(() => _selectedIds.clear());
  }

  String get _title {
    switch (widget.status) {
      case 'total':
        return 'All Documents';
      case 'active':
        return 'Active Documents';
      case 'expiring_soon':
        return 'Expiring Soon';
      case 'expired':
        return 'Expired Documents';
      default:
        return 'Documents';
    }
  }

  String get _emptyTitle {
    switch (widget.status) {
      case 'total':
        return 'No Documents';
      case 'active':
        return 'No Active Documents';
      case 'expiring_soon':
        return 'No Expiring Soon Documents';
      case 'expired':
        return 'No Expired Documents';
      default:
        return 'No Documents';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection)
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        title: Text(_isSelectionMode ? '${_selectedIds.length} Selected' : _title),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Documents'),
                        content: Text('Delete ${_selectedIds.length} document(s)?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await context.read<DocumentProvider>().deleteDocuments(_selectedIds.toList());
                      _clearSelection();
                      _loadDocuments();
                    }
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.push('/search'),
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? EmptyState(
                  icon: Icons.folder_open,
                  title: _emptyTitle,
                  subtitle: '',
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
    );
  }
}
