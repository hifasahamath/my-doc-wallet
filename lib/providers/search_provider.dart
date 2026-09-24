import 'package:flutter/foundation.dart';

import 'package:my_doc_wallet/data/models/document.dart';
import 'package:my_doc_wallet/data/repositories/document_repository.dart';

/// Search state and query execution.
class SearchProvider extends ChangeNotifier {
  final DocumentRepository _repo;

  String _query = '';
  List<Document> _results = [];
  bool _isSearching = false;

  SearchProvider(this._repo);

  String get query => _query;
  List<Document> get results => _results;
  bool get isSearching => _isSearching;

  Future<void> search(String query) async {
    _query = query;
    if (query.trim().isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    _results = await _repo.search(query.trim());
    _isSearching = false;
    notifyListeners();
  }

  void clear() {
    _query = '';
    _results = [];
    notifyListeners();
  }
}
