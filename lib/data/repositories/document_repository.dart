import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:my_doc_wallet/data/database/database_helper.dart';
import 'package:my_doc_wallet/data/models/document.dart';
import 'package:my_doc_wallet/data/models/document_version.dart';
import 'package:my_doc_wallet/data/models/custom_field.dart';

/// CRUD operations for documents, tags, custom fields, and versions.
class DocumentRepository {
  final _uuid = const Uuid();

  Future<Database> get _db => DatabaseHelper.instance.database;

  // ── Documents ──────────────────────────────────────────────────────────

  Future<List<Document>> getAll({String? sortBy, bool descending = true}) async {
    final db = await _db;
    final orderBy = '${sortBy ?? 'updated_at'} ${descending ? 'DESC' : 'ASC'}';
    final rows = await db.rawQuery('''
      SELECT d.*, c.name AS category_name
      FROM documents d
      LEFT JOIN categories c ON d.category_id = c.id
      ORDER BY $orderBy
    ''');
    return _mapRowsToDocuments(db, rows);
  }

  Future<List<Document>> _mapRowsToDocuments(Database db, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return [];

    // Bulk fetch tags to avoid N+1 queries
    final docIds = rows.map((r) => "'${r['id']}'").join(',');
    final tagsRows = await db.rawQuery('''
      SELECT dt.document_id, t.name
      FROM tags t
      JOIN document_tags dt ON t.id = dt.tag_id
      WHERE dt.document_id IN ($docIds)
    ''');
    
    final tagsByDoc = <String, List<String>>{};
    for (final row in tagsRows) {
      final docId = row['document_id'] as String;
      final tagName = row['name'] as String;
      tagsByDoc.putIfAbsent(docId, () => []).add(tagName);
    }

    return rows.map((row) {
      final docId = row['id'] as String;
      return Document.fromMap(row).copyWith(tags: tagsByDoc[docId] ?? []);
    }).toList();
  }

  Future<Document?> getById(String id) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT d.*, c.name AS category_name
      FROM documents d
      LEFT JOIN categories c ON d.category_id = c.id
      WHERE d.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    final tags = await getTagsForDocument(id);
    return Document.fromMap(rows.first).copyWith(tags: tags);
  }

  Future<List<Document>> getByCategory(String categoryId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT d.*, c.name AS category_name
      FROM documents d
      LEFT JOIN categories c ON d.category_id = c.id
      WHERE d.category_id = ?
      ORDER BY d.updated_at DESC
    ''', [categoryId]);
    return _mapRowsToDocuments(db, rows);
  }

  Future<List<Document>> getFavorites() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT d.*, c.name AS category_name
      FROM documents d
      LEFT JOIN categories c ON d.category_id = c.id
      WHERE d.is_favorite = 1
      ORDER BY d.updated_at DESC
    ''');
    return _mapRowsToDocuments(db, rows);
  }

  Future<List<Document>> getExpiringSoon(int withinDays) async {
    final db = await _db;
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: withinDays));
    final rows = await db.rawQuery('''
      SELECT d.*, c.name AS category_name
      FROM documents d
      LEFT JOIN categories c ON d.category_id = c.id
      WHERE d.expiry_date IS NOT NULL
        AND d.expiry_date >= ?
        AND d.expiry_date <= ?
      ORDER BY d.expiry_date ASC
    ''', [now.toIso8601String().substring(0, 10), cutoff.toIso8601String().substring(0, 10)]);
    return _mapRowsToDocuments(db, rows);
  }

  Future<List<Document>> getExpired() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await db.rawQuery('''
      SELECT d.*, c.name AS category_name
      FROM documents d
      LEFT JOIN categories c ON d.category_id = c.id
      WHERE d.expiry_date IS NOT NULL AND d.expiry_date < ?
      ORDER BY d.expiry_date DESC
    ''', [now]);
    return _mapRowsToDocuments(db, rows);
  }

  Future<void> insert(Document doc) async {
    final db = await _db;
    await db.insert('documents', doc.toMap());
  }

  Future<void> update(Document doc) async {
    final db = await _db;
    await db.update('documents', doc.toMap(), where: 'id = ?', whereArgs: [doc.id]);
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await _db;
    await db.update('documents', {'is_favorite': isFavorite ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  /// Move a single document to a different category.
  Future<void> moveToCategory(String documentId, String categoryId) async {
    final db = await _db;
    await db.update(
      'documents',
      {'category_id': categoryId, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [documentId],
    );
  }

  /// Move all documents from one category to another.
  Future<void> moveDocumentsByCategory(String fromCategoryId, String toCategoryId) async {
    final db = await _db;
    await db.update(
      'documents',
      {'category_id': toCategoryId, 'updated_at': DateTime.now().toIso8601String()},
      where: 'category_id = ?',
      whereArgs: [fromCategoryId],
    );
  }

  // ── Dashboard stats ────────────────────────────────────────────────────

  Future<Map<String, int>> getStats() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String().substring(0, 10);
    final cutoff30 = DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10);

    final total = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM documents')) ??
        0;
    final expired = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM documents WHERE expiry_date IS NOT NULL AND expiry_date < ?',
            [now])) ??
        0;
    final expiring = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM documents WHERE expiry_date IS NOT NULL AND expiry_date >= ? AND expiry_date <= ?',
            [now, cutoff30])) ??
        0;
    final active = total - expired;

    return {
      'total': total,
      'active': active,
      'expiring': expiring,
      'expired': expired,
    };
  }

  // ── Tags ───────────────────────────────────────────────────────────────

  Future<List<String>> getTagsForDocument(String documentId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT t.name FROM tags t
      INNER JOIN document_tags dt ON t.id = dt.tag_id
      WHERE dt.document_id = ?
    ''', [documentId]);
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<void> setTagsForDocument(String documentId, List<String> tagNames) async {
    final db = await _db;
    // Remove existing
    await db.delete('document_tags', where: 'document_id = ?', whereArgs: [documentId]);
    // Add new
    for (final name in tagNames) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      // Upsert tag
      var tagRows = await db.query('tags', where: 'name = ?', whereArgs: [trimmed]);
      String tagId;
      if (tagRows.isEmpty) {
        tagId = _uuid.v4();
        await db.insert('tags', {'id': tagId, 'name': trimmed});
      } else {
        tagId = tagRows.first['id'] as String;
      }
      await db.insert('document_tags', {
        'document_id': documentId,
        'tag_id': tagId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ── Custom fields ──────────────────────────────────────────────────────

  Future<List<CustomField>> getCustomFields(String documentId) async {
    final db = await _db;
    final rows = await db.query('custom_fields',
        where: 'document_id = ?', whereArgs: [documentId]);
    return rows.map((r) => CustomField.fromMap(r)).toList();
  }

  Future<void> setCustomFields(String documentId, List<CustomField> fields) async {
    final db = await _db;
    await db.delete('custom_fields', where: 'document_id = ?', whereArgs: [documentId]);
    for (final f in fields) {
      await db.insert('custom_fields', f.toMap());
    }
  }

  // ── Versions ───────────────────────────────────────────────────────────

  Future<List<DocumentVersion>> getVersions(String documentId) async {
    final db = await _db;
    final rows = await db.query('document_versions',
        where: 'document_id = ?',
        whereArgs: [documentId],
        orderBy: 'version_number DESC');
    return rows.map((r) => DocumentVersion.fromMap(r)).toList();
  }

  Future<void> insertVersion(DocumentVersion version) async {
    final db = await _db;
    await db.insert('document_versions', version.toMap());
  }

  // ── Search ─────────────────────────────────────────────────────────────

  Future<List<Document>> search(String query) async {
    final db = await _db;
    final q = '%${query.toLowerCase()}%';
    final rows = await db.rawQuery('''
      SELECT DISTINCT d.*, c.name AS category_name
      FROM documents d
      LEFT JOIN categories c ON d.category_id = c.id
      LEFT JOIN document_tags dt ON d.id = dt.document_id
      LEFT JOIN tags t ON dt.tag_id = t.id
      WHERE LOWER(d.name) LIKE ?
         OR LOWER(c.name) LIKE ?
         OR LOWER(d.document_number) LIKE ?
         OR LOWER(d.notes) LIKE ?
         OR LOWER(d.ocr_text) LIKE ?
         OR LOWER(t.name) LIKE ?
      ORDER BY d.updated_at DESC
    ''', [q, q, q, q, q, q]);
    return rows.map((r) => Document.fromMap(r)).toList();
  }

  // ── Document counts per category ───────────────────────────────────────

  Future<Map<String, int>> getDocumentCountsByCategory() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT category_id, COUNT(*) as cnt FROM documents GROUP BY category_id
    ''');
    return {for (final r in rows) r['category_id'] as String: r['cnt'] as int};
  }
}
