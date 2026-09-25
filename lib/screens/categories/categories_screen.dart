import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/data/models/category.dart';
import 'package:my_doc_wallet/providers/category_provider.dart';
import 'package:my_doc_wallet/widgets/empty_state.dart';

/// Screen listing all categories (built-in and custom) with reorder support.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                context.read<CategoryProvider>().createCustomCategory(name, 'folder', 0xFF9E9E9E);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isReorderMode ? 'Reorder Categories' : 'Categories',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isReorderMode)
            TextButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Done'),
              onPressed: () => setState(() => _isReorderMode = false),
            )
          else ...[
            if (provider.categories.length > 1)
              IconButton(
                icon: const Icon(Icons.reorder),
                tooltip: 'Reorder',
                onPressed: () => setState(() => _isReorderMode = true),
              ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create New'),
              onPressed: _showAddCategoryDialog,
            ),
          ],
        ],
      ),
      body: provider.isLoading && provider.categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.categories.isEmpty
              ? const EmptyState(
                  icon: Icons.category_outlined,
                  title: 'No categories',
                  subtitle: 'Create a custom category to organize your documents.',
                )
              : _isReorderMode
                  ? _buildReorderList(provider, theme)
                  : _buildCategoryGrid(provider, theme),
    );
  }

  Widget _buildReorderList(CategoryProvider provider, ThemeData theme) {
    if (provider.categories.isEmpty) return const SizedBox.shrink();
    
    // Separate uncategorized from reorderable list
    final uncategorized = provider.categories.firstWhere((c) => c.id == 'uncategorized', orElse: () => provider.categories.first);
    final reorderableCategories = provider.categories.where((c) => c.id != 'uncategorized').toList();

    return Column(
      children: [
        if (uncategorized.id == 'uncategorized')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(uncategorized.color).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.folder_open, color: Color(uncategorized.color)),
                ),
                title: Text(uncategorized.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('${provider.getCount(uncategorized.id)} Document${provider.getCount(uncategorized.id) == 1 ? '' : 's'}'),
                trailing: const Icon(Icons.lock_outline, color: Colors.grey),
              ),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16).copyWith(bottom: 80),
            itemCount: reorderableCategories.length,
            onReorderItem: (oldIndex, newIndex) {
              final newCategories = List<Category>.from(reorderableCategories);
              final item = newCategories.removeAt(oldIndex);
              newCategories.insert(newIndex, item);
              
              // Prepend uncategorized back to the list
              final finalIds = [if (uncategorized.id == 'uncategorized') 'uncategorized', ...newCategories.map((c) => c.id)];
              provider.reorderCategories(finalIds);
            },
            itemBuilder: (context, index) {
              final category = reorderableCategories[index];
              final count = provider.getCount(category.id);
              return Card(
                key: ValueKey(category.id),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(category.color).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.folder, color: Color(category.color)),
                  ),
                  title: Text(category.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('$count Document${count == 1 ? '' : 's'}'),
                  trailing: const Icon(Icons.drag_handle),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(CategoryProvider provider, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () => provider.loadCategories(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16).copyWith(bottom: 80),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: provider.categories.length,
        itemBuilder: (context, index) {
          final category = provider.categories[index];
          final count = provider.getCount(category.id);

          return Card(
            child: InkWell(
              onTap: () {
                context.push('/category/${category.id}', extra: category.name);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(category.color).withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.folder, color: Color(category.color), size: 28),
                    ),
                    const Spacer(),
                    Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count Document${count == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
