import 'package:flutter/foundation.dart' hide Category;

import 'package:my_doc_wallet/data/models/category.dart';
import 'package:my_doc_wallet/data/repositories/category_repository.dart';
import 'package:my_doc_wallet/data/repositories/document_repository.dart';

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
}
