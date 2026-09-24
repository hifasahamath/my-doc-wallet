import 'package:flutter/foundation.dart';

import 'package:my_doc_wallet/data/models/document.dart';
import 'package:my_doc_wallet/data/repositories/document_repository.dart';

/// Dashboard statistics and quick-access data.
class DashboardProvider extends ChangeNotifier {
  final DocumentRepository _repo;

  Map<String, int> _stats = {};
  List<Document> _favorites = [];
  List<Document> _expiringSoon = [];
  bool _isLoading = false;

  DashboardProvider(this._repo);

  Map<String, int> get stats => _stats;
  List<Document> get favorites => _favorites;
  List<Document> get expiringSoon => _expiringSoon;
  bool get isLoading => _isLoading;

  int get totalCount => _stats['total'] ?? 0;
  int get activeCount => _stats['active'] ?? 0;
  int get expiringCount => _stats['expiring'] ?? 0;
  int get expiredCount => _stats['expired'] ?? 0;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();
    _stats = await _repo.getStats();
    _favorites = await _repo.getFavorites();
    _expiringSoon = await _repo.getExpiringSoon(30);
    _isLoading = false;
    notifyListeners();
  }
}
