import 'package:uuid/uuid.dart';

import 'package:my_doc_wallet/data/database/database_helper.dart';
import 'package:my_doc_wallet/data/models/category.dart';

/// CRUD operations for document categories.
class CategoryRepository {
  final _uuid = const Uuid();

  Future<List<Category>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('categories', orderBy: 'sort_order ASC');
    return rows.map((r) => Category.fromMap(r)).toList();
  }

  Future<Category?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<void> insert(Category category) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('categories', category.toMap());
  }

  Future<Category> createCustom(String name, String iconName, int color) async {
    // Assign sort_order after the current maximum
    final db = await DatabaseHelper.instance.database;
    final maxOrder = (await db.rawQuery(
      'SELECT MAX(sort_order) as m FROM categories',
    )).first['m'] as int? ?? 0;

    final cat = Category(
      id: _uuid.v4(),
      name: name,
      iconName: iconName,
      color: color,
      isCustom: true,
      sortOrder: maxOrder + 1,
    );
    await insert(cat);
    return cat;
  }

  Future<void> update(Category category) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  /// Delete any category (built-in or custom).
  /// Callers must handle moving documents BEFORE calling this.
  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  /// Persist the display order for all categories.
  Future<void> reorder(List<String> orderedIds) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        'categories',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }
}
