import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/utils/app_failure.dart';

/// Handles capturing/selecting photos (camera + gallery) and the
/// associated permission flow. Actual live camera preview (viewfinder) is
/// driven by the `camera` package directly inside the scanner feature,
/// since it needs a `CameraController` tied to widget lifecycle — this
/// service covers permission requests and the gallery/picker fallback
/// path used by both the scanner and "add ingredient" flows.
class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Requests camera permission, throwing [AppFailure.cameraPermissionDenied]
  /// if denied. Returns normally if granted.
  Future<void> ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return;

    final result = await Permission.camera.request();
    if (!result.isGranted) {
      throw AppFailure.cameraPermissionDenied();
    }
  }

  /// Requests photo library permission, throwing
  /// [AppFailure.photoPermissionDenied] if denied. On Android this maps to
  /// the photos/storage permission; on iOS to the photo library permission.
  Future<void> ensurePhotoPermission() async {
    final permission = Platform.isIOS ? Permission.photos : Permission.photos;
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return;

    final result = await permission.request();
    if (!result.isGranted && !result.isLimited) {
      throw AppFailure.photoPermissionDenied();
    }
  }

  /// Picks an image from the gallery. Returns null if the user cancels.
  Future<File?> pickFromGallery() async {
    await ensurePhotoPermission();
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (picked == null) return null;
      return File(picked.path);
    } catch (_) {
      throw AppFailure.generic();
    }
  }

  /// Captures a photo using the system camera UI (used as a simple
  /// fallback path / on platforms where the custom live preview isn't
  /// available). The primary scanner screen uses `camera` package directly
  /// for the full custom viewfinder experience.
  Future<File?> captureWithSystemCamera() async {
    await ensureCameraPermission();
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return null;
      return File(picked.path);
    } catch (_) {
      throw AppFailure.generic();
    }
  }
}
