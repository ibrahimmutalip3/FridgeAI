/// A user-facing failure with a friendly message. Every layer that can fail
/// (network, AI parsing, camera, storage) converts raw exceptions into this
/// type so the UI never has to display a raw stack trace or exception.
class AppFailure implements Exception {
  final String message;
  final AppFailureType type;

  const AppFailure(this.message, {this.type = AppFailureType.unknown});

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

  factory AppFailure.cameraPermissionDenied() => const AppFailure(
        'Camera access is needed to scan your food. You can enable it in Settings.',
        type: AppFailureType.permission,
      );

  factory AppFailure.photoPermissionDenied() => const AppFailure(
        'Photo library access is needed to pick an image. You can enable it in Settings.',
        type: AppFailureType.permission,
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
