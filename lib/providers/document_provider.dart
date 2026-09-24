import 'package:flutter/foundation.dart';

import 'package:my_doc_wallet/data/models/document.dart';
import 'package:my_doc_wallet/data/repositories/document_repository.dart';
import 'package:my_doc_wallet/services/document_service.dart';
import 'package:my_doc_wallet/services/notification_service.dart';

enum DocumentSortOption {
  recentlyUpdated,
  nameAsc,
  expiryDateAsc,
  categoryName,
}

/// State management for the document list.
class DocumentProvider extends ChangeNotifier {
  final DocumentRepository _repo;
  final DocumentService _docService;
  final NotificationService _notifications;

  List<Document> _documents = [];
  bool _isLoading = false;
  String? _error;
  
  DocumentSortOption _sortOption = DocumentSortOption.recentlyUpdated;

  DocumentProvider(this._repo, this._docService, this._notifications);

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DocumentSortOption get sortOption => _sortOption;

  void setSortOption(DocumentSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    _applySort();
    notifyListeners();
  }

  void _applySort([List<Document>? docs]) {
    final list = docs ?? _documents;
    switch (_sortOption) {
      case DocumentSortOption.recentlyUpdated:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case DocumentSortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case DocumentSortOption.expiryDateAsc:
        list.sort((a, b) {
          if (a.expiryDate == null && b.expiryDate == null) return 0;
          if (a.expiryDate == null) return 1;
          if (b.expiryDate == null) return -1;
          return a.expiryDate!.compareTo(b.expiryDate!);
        });
        break;
      case DocumentSortOption.categoryName:
        list.sort((a, b) {
          final catA = a.categoryName ?? '';
          final catB = b.categoryName ?? '';
          final cmp = catA.compareTo(catB);
          if (cmp != 0) return cmp;
          return a.name.compareTo(b.name);
        });
        break;
    }
  }

  Future<void> loadDocuments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _documents = await _repo.getAll();
      _applySort();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Document?> getDocument(String id) => _repo.getById(id);

  Future<List<Document>> getByCategory(String categoryId) async {
    final docs = await _repo.getByCategory(categoryId);
    _applySort(docs);
    return docs;
  }

  Future<Document> importFile({
    required String sourcePath,
    required String name,
    required String categoryId,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    List<String> tags = const [],
  }) async {
    final doc = await _docService.importFile(
      sourcePath: sourcePath,
      name: name,
      categoryId: categoryId,
      documentNumber: documentNumber,
      issueDate: issueDate,
      expiryDate: expiryDate,
      notes: notes,
      tags: tags,
    );
    if (doc.expiryDate != null) {
      await _notifications.scheduleExpiryReminders(doc);
    }
    await loadDocuments();
    return doc;
  }

  Future<Document> createFromScan({
    required List<String> imagePaths,
    required String name,
    required String categoryId,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    List<String> tags = const [],
  }) async {
    final doc = await _docService.createFromScannedImages(
      imagePaths: imagePaths,
      name: name,
      categoryId: categoryId,
      documentNumber: documentNumber,
      issueDate: issueDate,
      expiryDate: expiryDate,
      notes: notes,
      tags: tags,
    );
    if (doc.expiryDate != null) {
      await _notifications.scheduleExpiryReminders(doc);
    }
    await loadDocuments();
    return doc;
  }

  Future<void> updateDocument(Document doc) async {
    await _docService.updateDocument(doc);
    if (doc.expiryDate != null) {
      await _notifications.scheduleExpiryReminders(doc);
    } else {
      await _notifications.cancelReminders(doc.id);
    }
    await loadDocuments();
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await _repo.toggleFavorite(id, isFavorite);
    await loadDocuments();
  }

  Future<void> deleteDocument(String id) async {
    await _notifications.cancelReminders(id);
    await _docService.deleteDocument(id);
    await loadDocuments();
  }

  /// Delete multiple documents at once.
  Future<void> deleteDocuments(List<String> ids) async {
    for (final id in ids) {
      await _notifications.cancelReminders(id);
      await _docService.deleteDocument(id);
    }
    await loadDocuments();
  }

  Future<void> setTags(String documentId, List<String> tags) async {
    await _repo.setTagsForDocument(documentId, tags);
  }

  /// Move a single document to a different category.
  Future<void> moveToCategory(String documentId, String categoryId) async {
    await _repo.moveToCategory(documentId, categoryId);
    await loadDocuments();
  }

  /// Move multiple documents to a different category.
  Future<void> moveMultipleToCategory(List<String> documentIds, String categoryId) async {
    for (final id in documentIds) {
      await _repo.moveToCategory(id, categoryId);
    }
    await loadDocuments();
  }

  /// Toggle favorite for multiple documents.
  Future<void> toggleFavoriteMultiple(List<String> ids, bool isFavorite) async {
    for (final id in ids) {
      await _repo.toggleFavorite(id, isFavorite);
    }
    await loadDocuments();
  }
}
