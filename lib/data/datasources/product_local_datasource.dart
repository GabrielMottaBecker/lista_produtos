import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';

/// Gerencia toda a persistência local.
///
/// • Em dispositivos móveis/desktop → SQLite via sqflite.
/// • Em Flutter Web (onde sqflite não é suportado) → armazenamento
///   em memória, suficiente para fins didáticos durante a sessão.
class ProductLocalDatasource {
  static final ProductLocalDatasource _instance =
      ProductLocalDatasource._internal();
  factory ProductLocalDatasource() => _instance;
  ProductLocalDatasource._internal();

  // ── Armazenamento em memória (usado apenas na Web) ─────────────
  final List<ProductModel> _memoryStore = [];
  int _nextId = 1000;

  // ── SQLite (usado em mobile / desktop) ─────────────────────────
  Database? _db;

  Future<Database> get _database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'produtos.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, _) => _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migração: adiciona coluna isLocal se vier de versão anterior
          try {
            await db.execute(
                'ALTER TABLE products ADD COLUMN isLocal INTEGER NOT NULL DEFAULT 0');
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        price REAL NOT NULL,
        image TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        ratingRate REAL NOT NULL DEFAULT 0,
        ratingCount INTEGER NOT NULL DEFAULT 0,
        isLocal INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ── Leitura ────────────────────────────────────────────────────

  Future<bool> get hasData async {
    if (kIsWeb) return _memoryStore.isNotEmpty;
    final db = await _database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM products');
    return (result.first['c'] as int) > 0;
  }

  Future<List<ProductModel>> getAllProducts() async {
    if (kIsWeb) return List.unmodifiable(_memoryStore);
    final db = await _database;
    final maps = await db.query('products');
    return maps.map(ProductModel.fromMap).toList();
  }

  Future<ProductModel?> getProductById(int id) async {
    if (kIsWeb) {
      try {
        return _memoryStore.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }
    final db = await _database;
    final maps =
        await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ProductModel.fromMap(maps.first);
  }

  // ── Escrita ────────────────────────────────────────────────────

  Future<int> insertProduct(ProductModel product) async {
    if (kIsWeb) {
      if (product.id != null) {
        _memoryStore.removeWhere((p) => p.id == product.id);
        _memoryStore.add(product);
        return product.id!;
      } else {
        final newId = _nextId++;
        _memoryStore.add(ProductModel(
          id: newId,
          title: product.title,
          price: product.price,
          image: product.image,
          description: product.description,
          category: product.category,
          ratingRate: product.ratingRate,
          ratingCount: product.ratingCount,
          isLocal: product.isLocal,
        ));
        return newId;
      }
    }
    final db = await _database;
    return db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertAll(List<ProductModel> products) async {
    if (kIsWeb) {
      for (final p in products) {
        await insertProduct(p);
      }
      return;
    }
    final db = await _database;
    final batch = db.batch();
    for (final p in products) {
      batch.insert('products', p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<int> updateProduct(ProductModel product) async {
    if (kIsWeb) {
      final idx = _memoryStore.indexWhere((p) => p.id == product.id);
      if (idx == -1) return 0;
      _memoryStore[idx] = product;
      return 1;
    }
    final db = await _database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    if (kIsWeb) {
      final before = _memoryStore.length;
      _memoryStore.removeWhere((p) => p.id == id);
      return before - _memoryStore.length;
    }
    final db = await _database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    if (kIsWeb) {
      _memoryStore.clear();
      return;
    }
    final db = await _database;
    await db.delete('products');
  }
}
