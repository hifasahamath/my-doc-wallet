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
    final cat = Category(
      id: _uuid.v4(),
      name: name,
      iconName: iconName,
      color: color,
      isCustom: true,
      sortOrder: 100,
    );
    await insert(cat);
    return cat;
  }

  Future<void> update(Category category) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('categories', where: 'id = ? AND is_custom = 1', whereArgs: [id]);
  }
}
