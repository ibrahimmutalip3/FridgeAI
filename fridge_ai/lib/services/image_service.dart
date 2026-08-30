import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Opens the gallery picker for a small square-ish profile photo. Uses a
  /// tighter [maxWidth]/quality than [pickFromGallery] since an avatar is
  /// only ever shown at a few dozen logical pixels — no need to keep a
  /// full-resolution copy of the original around on disk.
  Future<File?> pickAvatarFromGallery() async {
    await ensurePhotoPermission();
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return null;
      return File(picked.path);
    } catch (_) {
      throw AppFailure.generic();
    }
  }

  /// Captures a new profile photo with the system camera, at avatar-sized
  /// resolution (see [pickAvatarFromGallery]).
  Future<File?> captureAvatarWithCamera() async {
    await ensureCameraPermission();
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked == null) return null;
      return File(picked.path);
    } catch (_) {
      throw AppFailure.generic();
    }
  }

  /// Copies [source] into a persistent `avatars/` folder inside the app's
  /// own documents directory (via `path_provider`) and returns the saved
  /// file's path, so the avatar survives app restarts and isn't lost if the
  /// OS clears the image_picker/system-camera temp cache the original file
  /// came from. Any previously saved avatar file is deleted first, so this
  /// never leaves stale images behind on disk.
  ///
  /// [previousPath], if given, is the [UserPreferences.avatarPath] value
  /// being replaced.
  Future<String> saveAvatarLocally(File source, {String? previousPath}) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final avatarsDir = Directory('${documentsDir.path}/avatars');
      if (!await avatarsDir.exists()) {
        await avatarsDir.create(recursive: true);
      }

      if (previousPath != null) {
        final previousFile = File(previousPath);
        if (await previousFile.exists()) {
          await previousFile.delete();
        }
      }

      final extension = source.path.contains('.') ? source.path.split('.').last : 'jpg';
      // Timestamped filename so a new pick never collides with (or gets
      // cached over) the previous avatar's file, even before the old one
      // above finishes deleting.
      final destinationPath =
          '${avatarsDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
      await source.copy(destinationPath);
      return destinationPath;
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  /// Deletes the locally-saved avatar file at [path], if it exists. Used
  /// when the user removes their avatar.
  Future<void> deleteAvatar(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Non-fatal — a leftover file on disk isn't worth surfacing an error
      // for; the preference is cleared regardless.
    }
  }
}
