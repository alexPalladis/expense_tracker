import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/expense.dart';

class DatabaseConfig {
  static final DatabaseConfig instance = DatabaseConfig._init();
  static Database? _database;

  DatabaseConfig._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL,
        description TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        amount        REAL NOT NULL,
        description   TEXT,
        category_id   INTEGER NOT NULL,
        date          TEXT NOT NULL,
        latitude      REAL,
        longitude     REAL,
        location_name TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getOrCreateUnknownCategory() async {
    final db = await database;
    final existing = await db.query('categories',
        where: 'name = ?', whereArgs: ['Άγνωστη']);
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    return await db.insert('categories', {
      'name': 'Άγνωστη',
      'description': 'Έξοδα χωρίς κατηγορία',
    });
  }

  Future<void> fixOrphanedExpenses() async {
  final db = await database;
  final orphaned = await db.rawQuery('''
    SELECT DISTINCT e.category_id
    FROM expenses e
    LEFT JOIN categories c ON e.category_id = c.id
    WHERE c.id IS NULL
  ''');

  if (orphaned.isEmpty) return;

  final unknownId = await getOrCreateUnknownCategory();
  for (final row in orphaned) {
    final oldId = row['category_id'] as int;
    await db.update('expenses', {'category_id': unknownId},
        where: 'category_id = ?', whereArgs: [oldId]);
  }
}

  Future<void> moveExpensesToCategory(int fromId, int toId) async {
    final db = await database;
    await db.update('expenses', {'category_id': toId},
        where: 'category_id = ?', whereArgs: [fromId]);
  }

  Future<int> getExpenseCountForCategory(int categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM expenses WHERE category_id = ?',
        [categoryId]);
    return result.first['count'] as int;
  }



  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update('expenses', expense.toMap(),
        where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }


  Future<List<Map<String, dynamic>>> getExpensesByCategory(
      String startDate, String endDate) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.name AS category_name,
             SUM(e.amount) AS total
      FROM expenses e
      JOIN categories c ON e.category_id = c.id
      WHERE e.date BETWEEN ? AND ?
      GROUP BY e.category_id
      ORDER BY total DESC
    ''', [startDate, endDate]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}