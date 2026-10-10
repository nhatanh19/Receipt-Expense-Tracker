import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../features/expenses/domain/expense_model.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vku_expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        receipt_image_path TEXT,
        raw_ocr_text TEXT
      )
    ''');
  }

  // --- CRUD Operations ---

  Future<int> insertExpense(ExpenseItem item) async {
    final db = await database;
    return await db.insert(
      'expenses',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseItem>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => ExpenseItem.fromMap(map)).toList();
  }

  Future<ExpenseItem?> getExpenseById(String id) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ExpenseItem.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateExpense(ExpenseItem item) async {
    final db = await database;
    return await db.update(
      'expenses',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteExpense(String id) async {
    final db = await database;
    
    // Also remove any stored image file if exists
    final item = await getExpenseById(id);
    if (item?.receiptImagePath != null) {
      try {
        final file = File(item!.receiptImagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
