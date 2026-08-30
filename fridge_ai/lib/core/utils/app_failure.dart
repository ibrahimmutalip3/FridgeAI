/// A user-facing failure with a friendly message. Every layer that can fail
/// (network, AI parsing, camera, storage) converts raw exceptions into this
/// type so the UI never has to display a raw stack trace or exception.
class AppFailure implements Exception {
  final String message;
  final AppFailureType type;

  /// True when the OS has permanently denied the permission (e.g. the user
  /// tapped "Don't allow" on iOS, or checked "Don't ask again" on Android).
  /// In this state calling `.request()` again is a no-op — the OS won't show
  /// the prompt a second time — so the UI must offer a way to jump straight
  /// to the app's system Settings page instead of retrying in-app.
  final bool isPermanentlyDenied;

  const AppFailure(
    this.message, {
    this.type = AppFailureType.unknown,
    this.isPermanentlyDenied = false,
  });

  factory AppFailure.noInternet() => const AppFailure(
        'No internet connection. Please check your network and try again.',
        type: AppFailureType.noInternet,
      );

  factory AppFailure.timeout() => const AppFailure(
        'That took too long to respond. Please try again.',
        type: AppFailureType.timeout,
      );

  factory AppFailure.apiError([String? detail]) => const AppFailure(
        'Something went wrong. Please try again.',
        type: AppFailureType.api,
      );

  factory AppFailure.rateLimit() => const AppFailure(
        "FridgeAI's brain is a little busy right now. Please wait a moment and try again.",
        type: AppFailureType.rateLimit,
      );

  factory AppFailure.invalidResponse() => const AppFailure(
        "I had trouble understanding that. Let's try again.",
        type: AppFailureType.invalidResponse,
      );

  factory AppFailure.cameraPermissionDenied({bool isPermanentlyDenied = false}) => AppFailure(
        isPermanentlyDenied
            ? 'Camera access is off for FridgeAI. Turn it on in Settings to scan food.'
            : 'Camera access is needed to scan your food.',
        type: AppFailureType.permission,
        isPermanentlyDenied: isPermanentlyDenied,
      );

  factory AppFailure.photoPermissionDenied({bool isPermanentlyDenied = false}) => AppFailure(
        isPermanentlyDenied
            ? 'Photo library access is off for FridgeAI. Turn it on in Settings to pick a photo.'
            : 'Photo library access is needed to pick an image.',
        type: AppFailureType.permission,
        isPermanentlyDenied: isPermanentlyDenied,
      );

  factory AppFailure.noFoodDetected() => const AppFailure(
        "I couldn't recognize any food in that photo. Try a clearer, well-lit shot.",
        type: AppFailureType.noFoodDetected,
      );

  factory AppFailure.missingApiKey() => const AppFailure(
        'AI features are not configured for this build. Please contact the app owner.',
        type: AppFailureType.configuration,
      );

  factory AppFailure.storage() => const AppFailure(
        "We couldn't save that. Please try again.",
        type: AppFailureType.storage,
      );

  factory AppFailure.generic() => const AppFailure(
        'Something went wrong. Please try again.',
        type: AppFailureType.unknown,
      );

  @override
  String toString() => message;
}

enum AppFailureType {
  noInternet,
  timeout,
  api,
  rateLimit,
  invalidResponse,
  permission,
  noFoodDetected,
  configuration,
  storage,
  unknown,
}
