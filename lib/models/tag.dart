import 'package:isar/isar.dart';

part 'tag.g.dart';

@collection
class Tag {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  String? description;

  String? color; // Hex color code for UI customization

  @Index()
  late DateTime createdAt;

  DateTime? updatedAt;

  // Helper methods
  bool get hasColor => color != null && color!.isNotEmpty;
}
