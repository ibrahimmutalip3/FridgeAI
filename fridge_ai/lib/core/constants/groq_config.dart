/// Centralized Groq API configuration.
///
/// The API key is injected at BUILD TIME via `--dart-define=GROQ_API_KEY=...`
/// and must never be hardcoded or committed to the repository.
///
/// Model names are kept here as single-source-of-truth constants so they can
/// be swapped easily if Groq changes/renames/deprecates a model.
class GroqConfig {
  GroqConfig._();

  /// Injected at build time by GitHub Actions:
  ///   flutter build apk --dart-define=GROQ_API_KEY=${{ secrets.GROQ_API_KEY }}
  static const String apiKey = String.fromEnvironment('GROQ_API_KEY');

  static const String baseUrl = 'https://api.groq.com/openai/v1';
  static const String chatCompletionsEndpoint = '$baseUrl/chat/completions';

  /// Vision-capable model used for analyzing food/fridge/grocery photos.
  /// Centralized here so it can be changed in one place if Groq updates
  /// their vision model lineup.
  static const String visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  /// Text model used for recipe generation from a confirmed ingredient list.
  /// A capable, fast instruction-following model is sufficient since no
  /// image understanding is required at this stage.
  static const String textModel = 'llama-3.3-70b-versatile';

  static const int maxTokensVision = 2048;
  static const int maxTokensRecipes = 4096;

  static const Duration requestTimeout = Duration(seconds: 45);

  static bool get hasApiKey => apiKey.isNotEmpty;

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };
}
