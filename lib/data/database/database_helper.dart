import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import 'package:my_doc_wallet/core/constants/app_constants.dart';
import 'package:my_doc_wallet/core/constants/category_constants.dart';

/// Manages the local SQLite database lifecycle including creation,
/// migrations, and default data seeding.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.databaseName);

    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        is_custom INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        document_number TEXT,
        issue_date TEXT,
        expiry_date TEXT,
        notes TEXT,
        ocr_text TEXT,
        is_favorite INTEGER DEFAULT 0,
        current_version INTEGER DEFAULT 1,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        thumbnail_path TEXT,
        page_count INTEGER DEFAULT 1,
        file_size INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        imported_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE document_tags (
        document_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (document_id, tag_id),
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_fields (
        id TEXT PRIMARY KEY,
        document_id TEXT NOT NULL,
        field_name TEXT NOT NULL,
        field_value TEXT NOT NULL,
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE document_versions (
        id TEXT PRIMARY KEY,
        document_id TEXT NOT NULL,
        version_number INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        thumbnail_path TEXT,
        page_count INTEGER DEFAULT 1,
        file_size INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE document_sets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        set_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE document_set_items (
        set_id TEXT NOT NULL,
        document_id TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        PRIMARY KEY (set_id, document_id),
        FOREIGN KEY (set_id) REFERENCES document_sets(id) ON DELETE CASCADE,
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE document_pages (
        id TEXT PRIMARY KEY,
        document_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');

    // Indices for common queries
    await db.execute(
        'CREATE INDEX idx_documents_category ON documents(category_id)');
    await db.execute(
        'CREATE INDEX idx_documents_expiry ON documents(expiry_date)');
    await db.execute(
        'CREATE INDEX idx_documents_favorite ON documents(is_favorite)');
    await db.execute(
        'CREATE INDEX idx_document_tags_doc ON document_tags(document_id)');
    await db.execute(
        'CREATE INDEX idx_custom_fields_doc ON custom_fields(document_id)');
    await db.execute(
        'CREATE INDEX idx_versions_doc ON document_versions(document_id)');

    // Seed built-in categories
    for (var i = 0; i < CategoryConstants.builtInCategories.length; i++) {
      final cat = CategoryConstants.builtInCategories[i];
      await db.insert('categories', {
        'id': cat.id,
        'name': cat.name,
        'icon': cat.iconName,
        'color': cat.color,
        'is_custom': 0,
        'sort_order': i,
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE documents ADD COLUMN imported_at TEXT');
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
