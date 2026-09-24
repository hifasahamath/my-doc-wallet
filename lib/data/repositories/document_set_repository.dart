import 'package:my_doc_wallet/data/database/database_helper.dart';
import 'package:my_doc_wallet/data/models/document.dart';
import 'package:my_doc_wallet/data/models/document_set.dart';

/// CRUD operations for document sets.
class DocumentSetRepository {
  Future<List<DocumentSet>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT ds.*,
        (SELECT COUNT(*) FROM document_set_items dsi WHERE dsi.set_id = ds.id) AS document_count
      FROM document_sets ds
      ORDER BY ds.updated_at DESC
    ''');
    return rows.map((r) => DocumentSet.fromMap(r)).toList();
  }

  Future<DocumentSet?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT ds.*,
        (SELECT COUNT(*) FROM document_set_items dsi WHERE dsi.set_id = ds.id) AS document_count
      FROM document_sets ds
      WHERE ds.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    return DocumentSet.fromMap(rows.first);
  }

  Future<void> insert(DocumentSet set) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('document_sets', set.toMap());
  }

  Future<void> update(DocumentSet set) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('document_sets', set.toMap(),
        where: 'id = ?', whereArgs: [set.id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('document_sets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Document>> getDocumentsInSet(String setId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT d.*, c.name AS category_name
      FROM documents d
      INNER JOIN document_set_items dsi ON d.id = dsi.document_id
      LEFT JOIN categories c ON d.category_id = c.id
      WHERE dsi.set_id = ?
      ORDER BY dsi.sort_order ASC
    ''', [setId]);
    return rows.map((r) => Document.fromMap(r)).toList();
  }

  Future<void> addDocumentToSet(String setId, String documentId) async {
    final db = await DatabaseHelper.instance.database;
    final maxOrder = await db.rawQuery(
        'SELECT MAX(sort_order) as m FROM document_set_items WHERE set_id = ?',
        [setId]);
    final order = ((maxOrder.first['m'] as int?) ?? -1) + 1;
    await db.insert('document_set_items', {
      'set_id': setId,
      'document_id': documentId,
      'sort_order': order,
    });
  }

  Future<void> removeDocumentFromSet(String setId, String documentId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('document_set_items',
        where: 'set_id = ? AND document_id = ?',
        whereArgs: [setId, documentId]);
  }
}
