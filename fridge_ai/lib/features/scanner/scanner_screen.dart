import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_failure.dart';
import '../../providers/core_providers.dart';
import 'widgets/scan_frame_overlay.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;
  FlashMode _flashMode = FlashMode.off;
  bool _permissionDenied = false;
  bool _permissionPermanentlyDenied = false;
  String? _errorMessage;
  // Set while the gallery permission is denied, so we can show an
  // in-place banner with a Settings shortcut instead of a dead-end SnackBar.
  AppFailure? _galleryPermissionFailure;

  // Toggled true for one frame on capture to trigger the shutter-flash
  // overlay below, then immediately back to false — see [_capture].
  bool _showCaptureFlash = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      await ref.read(imageServiceProvider).ensureCameraPermission();
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No camera is available on this device.');
        return;
      }
      final rearCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } on AppFailure catch (e) {
      if (e.type == AppFailureType.permission) {
        setState(() {
          _permissionDenied = true;
          _permissionPermanentlyDenied = e.isPermanentlyDenied;
        });
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      setState(() => _errorMessage = AppFailure.generic().message);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initFuture = _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await controller.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (_) {
      // Flash not supported on this device — ignore silently.
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }
    try {
      // Light tactile + a one-frame white flash the instant the shutter
      // fires, before the (network-bound) analysis screen even loads — the
      // capture itself should feel instant and satisfying regardless of
      // how long the AI step takes afterward.
      HapticFeedback.mediumImpact();
      setState(() => _showCaptureFlash = true);
      final file = await controller.takePicture();
      if (!mounted) return;
      setState(() => _showCaptureFlash = false);
      context.push(AppRoutes.aiAnalysis, extra: File(file.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppFailure.generic().message)),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      // Clear any previous gallery-permission banner before retrying.
      if (_galleryPermissionFailure != null) {
        setState(() => _galleryPermissionFailure = null);
      }
      final file = await ref.read(imageServiceProvider).pickFromGallery();
      if (file == null || !mounted) return;
      context.push(AppRoutes.aiAnalysis, extra: file);
    } on AppFailure catch (e) {
      if (!mounted) return;
      if (e.type == AppFailureType.permission) {
        // A SnackBar is a dead end here — the user has no way to act on it.
        // Show an in-place banner with a direct link to Settings instead.
        setState(() => _galleryPermissionFailure = e);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppFailure.generic().message)),
      );
    }
  }

  Future<void> _openSystemSettings() async {
    await ref.read(imageServiceProvider).openSystemSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_permissionDenied)
            _PermissionDeniedView(
              isPermanentlyDenied: _permissionPermanentlyDenied,
              onPickGallery: _pickFromGallery,
              onOpenSettings: _openSystemSettings,
              onRetry: () => setState(() => _initFuture = _initCamera()),
            )
          else if (_errorMessage != null)
            _CameraErrorView(message: _errorMessage!, onPickGallery: _pickFromGallery)
          else
            FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                final controller = _controller;
                if (controller == null || !controller.value.isInitialized) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                // A quick fade-in the first time each controller becomes
                // ready — otherwise the live feed just snaps into view the
                // instant initialization finishes, which reads as a glitch
                // rather than "the camera is starting up."
                return TweenAnimationBuilder<double>(
                  key: ValueKey(controller),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 340),
                  curve: Curves.easeOut,
                  builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.previewSize?.height ?? 1,
                          height: controller.value.previewSize?.width ?? 1,
                          child: CameraPreview(controller),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          const IgnorePointer(child: ScanFrameOverlay()),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showCaptureFlash ? 1 : 0,
              // Instant on, quick fade-out — a real camera shutter flash
              // reads as a snap, not a gentle cross-fade in either
              // direction.
              duration: Duration(milliseconds: _showCaptureFlash ? 0 : 180),
              curve: Curves.easeOut,
              child: const ColoredBox(color: Colors.white),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => context.pop(),
                  ),
                  Text(
                    'Scan Food',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  _RoundIconButton(
                    icon: _flashMode == FlashMode.off ? Icons.flash_off_rounded : Icons.flash_on_rounded,
                    onTap: _toggleFlash,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_galleryPermissionFailure != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: _PermissionBanner(
                          message: _galleryPermissionFailure!.message,
                          isPermanentlyDenied: _galleryPermissionFailure!.isPermanentlyDenied,
                          onOpenSettings: _openSystemSettings,
                          onDismiss: () => setState(() => _galleryPermissionFailure = null),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _RoundIconButton(
                          icon: Icons.photo_library_rounded,
                          onTap: _pickFromGallery,
                        ),
                        _CaptureButton(onTap: _capture),
                        const SizedBox(width: 52),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureButton extends StatefulWidget {
  const _CaptureButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<_CaptureButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 76,
          width: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.primaryOrange,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({
    required this.isPermanentlyDenied,
    required this.onPickGallery,
    required this.onOpenSettings,
    required this.onRetry,
  });

  final bool isPermanentlyDenied;
  final VoidCallback onPickGallery;
  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = AppFailure.cameraPermissionDenied(
      isPermanentlyDenied: isPermanentlyDenied,
    ).message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_rounded, color: Colors.white70, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isPermanentlyDenied)
              // The OS won't show the permission prompt again — the only
              // way forward is the Settings app, so make that the primary
              // action here.
              FilledButton.icon(
                onPressed: onOpenSettings,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open Settings'),
              )
            else
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Allow Camera Access'),
              ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: onPickGallery,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              child: const Text('Choose from gallery instead'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dismissible in-place banner used when a permission (typically the
/// gallery/photo library one) is denied while the camera view is still
/// usable behind it — as opposed to [_PermissionDeniedView], which takes
/// over the whole screen when the camera itself can't be shown.
class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.message,
    required this.isPermanentlyDenied,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  final String message;
  final bool isPermanentlyDenied;
  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  if (isPermanentlyDenied) ...[
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: onOpenSettings,
                      child: const Text(
                        'Open Settings',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            InkWell(
              onTap: onDismiss,
              child: const Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(Icons.close_rounded, color: Colors.white54, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.message, required this.onPickGallery});

  final String message;
  final VoidCallback onPickGallery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onPickGallery,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              child: const Text('Choose from gallery instead'),
            ),
          ],
        ),
      ),
    );
  }
}
