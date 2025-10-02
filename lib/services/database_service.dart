import 'dart:async';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/food_item.dart';
import '../models/tag.dart';
import 'image_service.dart';

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
    return await Isar.open([FoodItemSchema, TagSchema], directory: dir.path);
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
    return await isar.foodItems.filter().nameContains(query, caseSensitive: false).findAll();
  }

  Future<List<FoodItem>> getFoodItemsByTag(String tag) async {
    final isar = await database;
    return await isar.foodItems.filter().tagsElementContains(tag).findAll();
  }

  Future<List<FoodItem>> getExpiredFoodItems() async {
    final isar = await database;
    final now = DateTime.now();
    return await isar.foodItems.filter().expiryDateLessThan(now).findAll();
  }

  Future<List<FoodItem>> getExpiringSoonFoodItems({int days = 3}) async {
    final isar = await database;
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));
    return await isar.foodItems.filter().expiryDateBetween(now, futureDate).findAll();
  }

  Future<void> updateFoodItem(FoodItem foodItem) async {
    final isar = await database;
    await isar.writeTxn(() async {
      await isar.foodItems.put(foodItem);
    });
  }

  Future<void> deleteFoodItem(int id) async {
    final isar = await database;

    // Get the item first to check if it has an image
    final item = await isar.foodItems.get(id);

    await isar.writeTxn(() async {
      await isar.foodItems.delete(id);
    });

    // Delete the associated image file if it exists
    if (item?.imagePath != null) {
      await ImageService.deleteImage(item!.imagePath!);
    }
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

    return {'total': all.length, 'expired': expired, 'expiringSoon': expiringSoon, 'fresh': fresh};
  }

  // Get unique tags from food items (for backward compatibility)
  Future<List<String>> getAllTagsFromFoodItems() async {
    final isar = await database;
    final items = await isar.foodItems.where().findAll();
    final Set<String> allTags = {};

    for (var item in items) {
      allTags.addAll(item.tags);
    }

    return allTags.toList()..sort();
  }

  // Tag CRUD Operations
  Future<void> insertTag(Tag tag) async {
    final isar = await database;
    await isar.writeTxn(() async {
      await isar.tags.put(tag);
    });
  }

  Future<List<Tag>> getAllTags() async {
    final isar = await database;
    return await isar.tags.where().sortByName().findAll();
  }

  Future<Tag?> getTagById(int id) async {
    final isar = await database;
    return await isar.tags.get(id);
  }

  Future<Tag?> getTagByName(String name) async {
    final isar = await database;
    return await isar.tags.filter().nameEqualTo(name).findFirst();
  }

  Future<void> updateTag(Tag tag) async {
    final isar = await database;
    await isar.writeTxn(() async {
      tag.updatedAt = DateTime.now();
      await isar.tags.put(tag);
    });
  }

  Future<void> deleteTag(int id) async {
    final isar = await database;
    await isar.writeTxn(() async {
      await isar.tags.delete(id);
    });
  }

  Future<List<Tag>> searchTags(String query) async {
    final isar = await database;
    return await isar.tags.filter().nameContains(query, caseSensitive: false).findAll();
  }

  // Initialize default tags if none exist
  Future<void> initializeDefaultTags() async {
    final existingTags = await getAllTags();
    if (existingTags.isEmpty) {
      final defaultTags = ['Rau', 'Thịt', 'Đồ uống', 'Trái cây', 'Bánh kẹo'];

      for (String tagName in defaultTags) {
        final tag = Tag()
          ..name = tagName
          ..createdAt = DateTime.now();
        await insertTag(tag);
      }
    }
  }

  // Close database
  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
    }
  }
}
