import 'package:permission_handler/permission_handler.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:flutter/widgets.dart';

class PermissionService {
  /// Request camera permission without UI. Returns true if granted.
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request camera permission and, if denied/permanently denied, show a dialog
  /// that explains why the permission is needed and offers to open app settings.
  static Future<bool> requestCameraPermissionWithDialog(BuildContext context) async {
    final status = await Permission.camera.status;
    // Debug log status before requesting
    print('[PermissionService] camera status before request: $status');

    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    // Debug log result after requesting
    print('[PermissionService] camera request result: $result');
    if (result.isGranted) return true;

    // If permanently denied or restricted, show a dialog guiding the user to settings
    if (result.isPermanentlyDenied || result.isRestricted) {
      final open = await shadcn.showDialog<bool>(
        context: context,
        builder: (context) => shadcn.AlertDialog(
          title: const Text('Cần quyền truy cập'),
          content: const Text('Ứng dụng cần quyền camera để chụp ảnh. Vui lòng bật quyền trong Cài đặt.'),
          actions: [
            shadcn.GhostButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
            shadcn.PrimaryButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
              },
              child: const Text('Mở Cài đặt'),
            ),
          ],
        ),
      );

      if (open == true) {
        await openAppSettings();
      }
    } else {
      // simple denied (not permanent) - show an explanation toast/dialog optionally
      await shadcn.showDialog<void>(
        context: context,
        builder: (context) => shadcn.AlertDialog(
          title: const Text('Từ chối quyền'),
          content: const Text('Quyền truy cập camera đã bị từ chối. Bạn có thể thử lại hoặc bật quyền trong Cài đặt.'),
          actions: [shadcn.PrimaryButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
        ),
      );
    }

    return false;
  }
}
