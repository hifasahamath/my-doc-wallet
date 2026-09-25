import 'package:flutter/foundation.dart' hide Category;

import 'package:my_doc_wallet/data/models/category.dart';
import 'package:my_doc_wallet/data/repositories/category_repository.dart';
import 'package:my_doc_wallet/data/repositories/document_repository.dart';
import 'package:my_doc_wallet/data/database/database_helper.dart';

/// State management for categories.
class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repo;
  final DocumentRepository _docRepo;

  List<Category> _categories = [];
  Map<String, int> _documentCounts = {};
  bool _isLoading = false;

  CategoryProvider(this._repo, this._docRepo);

  List<Category> get categories => _categories;
  Map<String, int> get documentCounts => _documentCounts;
  bool get isLoading => _isLoading;

  int getCount(String categoryId) => _documentCounts[categoryId] ?? 0;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    _categories = await _repo.getAll();

    // Auto-migrate old 'other' category if it exists
    final hasOldOther = _categories.any((c) => c.id == 'other');
    if (hasOldOther) {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'categories', 
        {'id': 'uncategorized', 'name': 'Uncategorized', 'icon': 'folder_open'}, 
        where: 'id = ?', 
        whereArgs: ['other'],
      );
      // We don't need to update documents because category_id is a foreign key with CASCADE or we can just update it manually if needed.
      // Wait, SQLite doesn't cascade ON UPDATE by default unless specified. Let's just update the documents too.
      await db.update(
        'documents',
        {'category_id': 'uncategorized'},
        where: 'category_id = ?',
        whereArgs: ['other'],
      );
      _categories = await _repo.getAll();
    }
    // Ensure 'uncategorized' is always first and exists
    var uncategorizedIdx = _categories.indexWhere((c) => c.id == 'uncategorized');
    if (uncategorizedIdx == -1) {
      final db = await DatabaseHelper.instance.database;
      await db.insert('categories', {
        'id': 'uncategorized',
        'name': 'Uncategorized',
        'icon': 'folder_open',
        'color': 0xFF9E9E9E,
        'is_custom': 0,
        'sort_order': -1
      });
      _categories = await _repo.getAll();
      uncategorizedIdx = _categories.indexWhere((c) => c.id == 'uncategorized');
    }

    if (uncategorizedIdx > 0) {
      final uncategorized = _categories.removeAt(uncategorizedIdx);
      _categories.insert(0, uncategorized);
    }

    _documentCounts = await _docRepo.getDocumentCountsByCategory();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createCustomCategory(String name, String icon, int color) async {
    await _repo.createCustom(name, icon, color);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _repo.update(category);
    await loadCategories();
  }

  /// Delete a category. If [moveDocumentsTo] is provided, documents in the
  /// deleted category are moved to that category first.
  Future<void> deleteCategory(String id, {String? moveDocumentsTo}) async {
    if (moveDocumentsTo != null) {
      await _docRepo.moveDocumentsByCategory(id, moveDocumentsTo);
    }
    await _repo.delete(id);
    await loadCategories();
  }

  /// Reorder the category list. [orderedIds] is the new sequence of
  /// category IDs. Persists the order to the database.
  Future<void> reorderCategories(List<String> orderedIds) async {
    // Optimistic update for snappy UI
    final reordered = <Category>[];
    for (final id in orderedIds) {
      final cat = _categories.firstWhere((c) => c.id == id);
      reordered.add(cat.copyWith(sortOrder: orderedIds.indexOf(id)));
    }
    _categories = reordered;
    notifyListeners();

    // Persist
    await _repo.reorder(orderedIds);
  }
}
