import 'dart:async';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/food_item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Isar? _isar;

  Future<Isar> get database async {
    if (_isar != null) return _isar!;
    _isar = await _initDB();
    return _isar!;
  }

  Future<Isar> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [FoodItemSchema],
      directory: dir.path,
    );
  }

  // CRUD Operations
  Future<void> insertFoodItem(FoodItem foodItem) async {
    final isar = await database;
    await isar.writeTxn(() async {
      await isar.foodItems.put(foodItem);
    });
  }

  Future<List<FoodItem>> getAllFoodItems() async {
    final isar = await database;
    return await isar.foodItems.where().findAll();
  }

  Future<List<FoodItem>> getFoodItemsSortedByExpiry() async {
    final isar = await database;
    return await isar.foodItems.where().sortByExpiryDate().findAll();
  }

  Future<List<FoodItem>> searchFoodItems(String query) async {
    final isar = await database;
    return await isar.foodItems
        .filter()
        .nameContains(query, caseSensitive: false)
        .findAll();
  }

  Future<List<FoodItem>> getFoodItemsByTag(String tag) async {
    final isar = await database;
    return await isar.foodItems
        .filter()
        .tagsElementContains(tag)
        .findAll();
  }

  Future<List<FoodItem>> getExpiredFoodItems() async {
    final isar = await database;
    final now = DateTime.now();
    return await isar.foodItems
        .filter()
        .expiryDateLessThan(now)
        .findAll();
  }

  Future<List<FoodItem>> getExpiringSoonFoodItems({int days = 3}) async {
    final isar = await database;
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));
    return await isar.foodItems
        .filter()
        .expiryDateBetween(now, futureDate)
        .findAll();
  }

  Future<void> updateFoodItem(FoodItem foodItem) async {
    final isar = await database;
    await isar.writeTxn(() async {
      await isar.foodItems.put(foodItem);
    });
  }

  Future<void> deleteFoodItem(int id) async {
    final isar = await database;
    await isar.writeTxn(() async {
      await isar.foodItems.delete(id);
    });
  }

  Future<FoodItem?> getFoodItemById(int id) async {
    final isar = await database;
    return await isar.foodItems.get(id);
  }

  // Statistics
  Future<Map<String, int>> getStatistics() async {
    final isar = await database;
    final all = await isar.foodItems.where().findAll();
    
    int expired = 0;
    int expiringSoon = 0;
    int fresh = 0;
    
    for (var item in all) {
      if (item.isExpired) {
        expired++;
      } else if (item.isExpiringSoon) {
        expiringSoon++;
      } else {
        fresh++;
      }
    }
    
    return {
      'total': all.length,
      'expired': expired,
      'expiringSoon': expiringSoon,
      'fresh': fresh,
    };
  }

  // Get unique tags
  Future<List<String>> getAllTags() async {
    final isar = await database;
    final items = await isar.foodItems.where().findAll();
    final Set<String> allTags = {};
    
    for (var item in items) {
      allTags.addAll(item.tags);
    }
    
    return allTags.toList()..sort();
  }

  // Close database
  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
    }
  }
}