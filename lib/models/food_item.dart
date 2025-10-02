import 'package:isar/isar.dart';

part 'food_item.g.dart';

@collection
class FoodItem {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;

  String? description;

  String? imagePath;

  @Index()
  late DateTime expiryDate;

  late List<String> tags;

  @Index()
  late DateTime createdAt;

  // Helper methods
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  bool get isExpiringSoon {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference <= 3 && difference >= 0;
  }

  bool get isExpiredOrExpiringSoon => isExpired || isExpiringSoon;

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  String get expiryStatus {
    if (isExpired) return 'expired';
    if (isExpiringSoon) return 'expiring_soon';
    return 'fresh';
  }
}
