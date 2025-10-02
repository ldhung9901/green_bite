import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static const String _imagesFolder = 'food_images';

  /// Get the directory where food images are stored
  static Future<Directory> _getImagesDirectory() async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDocumentsDir.path, _imagesFolder));

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
  }

  /// Save an image from a temporary path to persistent storage
  /// Returns the persistent path, or null if failed
  static Future<String?> saveImage(String tempImagePath) async {
    try {
      final sourceFile = File(tempImagePath);
      if (!await sourceFile.exists()) {
        print('Source image file does not exist: $tempImagePath');
        return null;
      }

      final imagesDir = await _getImagesDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(tempImagePath)}';
      final destinationPath = path.join(imagesDir.path, fileName);

      await sourceFile.copy(destinationPath);

      print('Image saved successfully to: $destinationPath');
      return destinationPath;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  /// Delete an image file
  static Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        print('Image deleted: $imagePath');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Check if an image file exists
  static Future<bool> imageExists(String imagePath) async {
    try {
      return await File(imagePath).exists();
    } catch (e) {
      print('Error checking image existence: $e');
      return false;
    }
  }

  /// Clean up orphaned images (images not referenced by any food item)
  static Future<void> cleanupOrphanedImages(List<String> usedImagePaths) async {
    try {
      final imagesDir = await _getImagesDirectory();
      final imageFiles = await imagesDir.list().where((entity) => entity is File).cast<File>().toList();

      for (final file in imageFiles) {
        if (!usedImagePaths.contains(file.path)) {
          await file.delete();
          print('Deleted orphaned image: ${file.path}');
        }
      }
    } catch (e) {
      print('Error cleaning up orphaned images: $e');
    }
  }

  /// Get the size of all stored images in bytes
  static Future<int> getTotalImagesSize() async {
    try {
      final imagesDir = await _getImagesDirectory();
      int totalSize = 0;

      await for (final entity in imagesDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      print('Error calculating images size: $e');
      return 0;
    }
  }
}
