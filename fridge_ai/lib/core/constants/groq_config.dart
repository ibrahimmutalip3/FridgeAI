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
  ///
  /// NOTE: `meta-llama/llama-4-scout-17b-16e-instruct` (the previous value
  /// here) was deprecated by Groq on 07/17/2026 and now returns a
  /// `model_decommissioned` error for every request — which is exactly why
  /// every scan was failing with "I couldn't spot any food in that photo."
  /// regardless of how clear the picture was. `qwen/qwen3.6-27b` is Groq's
  /// current recommended replacement and is one of only two models Groq
  /// currently lists as vision-capable at all (see
  /// https://console.groq.com/docs/vision and
  /// https://console.groq.com/docs/deprecations). If Groq deprecates this
  /// one too, check those two pages again before picking a replacement —
  /// not every Groq model accepts image input.
  ///
  /// Also note: Groq currently serves this as a preview model, meaning it
  /// can be pulled with little/no notice (unlike production models, which
  /// get an announced deprecation window). If scans suddenly start failing
  /// again with an API error (not "no food found"), check
  /// https://console.groq.com/docs/vision first for a replacement model ID
  /// before assuming the bug is in this app's code.
  static const String visionModel = 'qwen/qwen3.6-27b';

  /// Text model used for recipe generation from a confirmed ingredient list.
  /// A capable, fast instruction-following model is sufficient since no
  /// image understanding is required at this stage.
  ///
  /// NOTE: `llama-3.3-70b-versatile` (the previous value here) was
  /// deprecated by Groq on 08/16/2026. `openai/gpt-oss-120b` is Groq's
  /// current recommended replacement.
  static const String textModel = 'openai/gpt-oss-120b';

  static const int maxTokensVision = 2048;
  static const int maxTokensRecipes = 4096;

  static const Duration requestTimeout = Duration(seconds: 45);

  static bool get hasApiKey => apiKey.isNotEmpty;

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };
}
