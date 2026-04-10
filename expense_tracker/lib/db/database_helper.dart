import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/expense.dart';

class DatabaseHelper {
  // Singleton pattern — only one instance exists in the whole app
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL,
        description TEXT
      )
    ''');

    // Create expenses table
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

  // ─── CATEGORY CRUD ───────────────────────────────────────────

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
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── EXPENSE CRUD ────────────────────────────────────────────

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
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── ANALYSIS QUERY ──────────────────────────────────────────

  // Returns totals per category between two dates, sorted descending
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