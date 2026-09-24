import 'package:flutter/foundation.dart';

import 'package:my_doc_wallet/data/models/document.dart';
import 'package:my_doc_wallet/data/models/document_set.dart';
import 'package:my_doc_wallet/data/repositories/document_set_repository.dart';

/// State management for document sets (travel, job application, etc.).
class DocumentSetProvider extends ChangeNotifier {
  final DocumentSetRepository _repo;

  List<DocumentSet> _sets = [];
  bool _isLoading = false;

  DocumentSetProvider(this._repo);

  List<DocumentSet> get sets => _sets;
  bool get isLoading => _isLoading;

  Future<void> loadSets() async {
    _isLoading = true;
    notifyListeners();
    _sets = await _repo.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createSet(DocumentSet set) async {
    await _repo.insert(set);
    await loadSets();
  }

  Future<void> updateSet(DocumentSet set) async {
    await _repo.update(set);
    await loadSets();
  }

  Future<void> deleteSet(String id) async {
    await _repo.delete(id);
    await loadSets();
  }

  Future<List<Document>> getDocumentsInSet(String setId) =>
      _repo.getDocumentsInSet(setId);

  Future<void> addDocument(String setId, String documentId) async {
    await _repo.addDocumentToSet(setId, documentId);
    await loadSets();
  }

  Future<void> removeDocument(String setId, String documentId) async {
    await _repo.removeDocumentFromSet(setId, documentId);
    await loadSets();
  }
}
