/// Centralized Unsplash API configuration, used to fetch a real photo for
/// each AI-generated recipe (see [RecipeImageResolver] in
/// services/recipe_image_resolver.dart).
///
/// The old approach hotlinked `source.unsplash.com` directly with no key
/// required — that endpoint was fully deprecated/shut down by Unsplash and
/// now returns nothing usable, which is why every recipe image silently
/// fell back to the bundled placeholder. The real Unsplash Search API
/// (`api.unsplash.com`) is still fully supported, but — unlike the old
/// Source endpoint — it requires an Access Key and returns JSON (a list of
/// matching photos) rather than redirecting straight to an image, so the
/// resolver has to make an actual HTTP request and read the photo URL back
/// out of the response.
///
/// The Access Key is free (Unsplash's free "Demo" tier: 50 requests/hour,
/// plenty for this app) — create one at https://unsplash.com/oauth/applications
/// and, like [GroqConfig.apiKey], inject it at BUILD TIME via
/// `--dart-define=UNSPLASH_ACCESS_KEY=...` (see the CI workflows under
/// .github/workflows, which already pass it through from a
/// `UNSPLASH_ACCESS_KEY` repo secret). It must never be hardcoded or
/// committed to the repository.
///
/// If no key is configured, [hasApiKey] is false and the resolver skips
/// straight to the bundled local placeholder — the app never breaks or
/// shows an error for a missing image, it just looks less lively.
class UnsplashConfig {
  UnsplashConfig._();

  /// Injected at build time by GitHub Actions:
  ///   flutter build apk --dart-define=UNSPLASH_ACCESS_KEY=${{ secrets.UNSPLASH_ACCESS_KEY }}
  static const String accessKey = String.fromEnvironment('UNSPLASH_ACCESS_KEY');

  static const String baseUrl = 'https://api.unsplash.com';
  static const String searchPhotosEndpoint = '$baseUrl/search/photos';

  static const Duration requestTimeout = Duration(seconds: 10);

  static bool get hasApiKey => accessKey.isNotEmpty;
}
