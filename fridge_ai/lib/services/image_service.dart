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
  ///
  /// If the permission was already permanently denied (iOS: user tapped
  /// "Don't Allow" once before; Android: "Don't ask again"), `.request()`
  /// would silently return `denied` again without showing any system
  /// prompt — so we short-circuit and surface `isPermanentlyDenied: true`
  /// right away, which tells the UI to offer a link to system Settings
  /// instead of retrying in-app.
  Future<void> ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return;

    if (status.isPermanentlyDenied || status.isRestricted) {
      throw AppFailure.cameraPermissionDenied(isPermanentlyDenied: true);
    }

    final result = await Permission.camera.request();
    if (!result.isGranted) {
      throw AppFailure.cameraPermissionDenied(
        isPermanentlyDenied: result.isPermanentlyDenied || result.isRestricted,
      );
    }
  }

  /// Requests photo library permission, throwing
  /// [AppFailure.photoPermissionDenied] if denied. On Android this maps to
  /// the photos/storage permission; on iOS to the photo library permission.
  Future<void> ensurePhotoPermission() async {
    final permission = Platform.isIOS ? Permission.photos : Permission.photos;
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return;

    if (status.isPermanentlyDenied || status.isRestricted) {
      throw AppFailure.photoPermissionDenied(isPermanentlyDenied: true);
    }

    final result = await permission.request();
    if (!result.isGranted && !result.isLimited) {
      throw AppFailure.photoPermissionDenied(
        isPermanentlyDenied: result.isPermanentlyDenied || result.isRestricted,
      );
    }
  }

  /// Opens the app's page in the OS Settings app, so the user can flip a
  /// permission that was permanently denied. This is the only way to
  /// recover from a permanently-denied state — the in-app request dialog
  /// won't be shown again by the OS.
  Future<bool> openSystemSettings() => openAppSettings();

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
