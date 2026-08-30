import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/unsplash_config.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';

/// FridgeAI has no custom backend, so this resolver is the single source of
/// truth for turning a [Recipe] or [Ingredient] into a concrete image
/// reference:
///
///  - Every recipe gets a real-photo URL by searching the Unsplash API
///    (https://api.unsplash.com/search/photos) for the short image search
///    phrase the AI returns alongside the recipe (`recipe.imageQuery`, e.g.
///    "creamy chicken rice bowl") and reading the first result's photo URL
///    back out of the JSON response — see [urlForQuery] / [urlForRecipe].
///
///    NOTE: this previously hotlinked `source.unsplash.com` directly, which
///    needed no key and no HTTP round trip of its own (it just redirected
///    straight to a matching photo). That endpoint has been fully shut down
///    by Unsplash — every request to it fails — which is exactly why every
///    recipe was silently falling back to a local placeholder. The real
///    Unsplash Search API used here is still fully supported, but requires
///    an Access Key ([UnsplashConfig.accessKey], injected at build time —
///    see unsplash_config.dart) and returns JSON rather than an image
///    redirect, so resolving a photo is now an async network call instead
///    of a synchronous string build.
///  - `FallbackImage` (see core/widgets/fallback_image.dart) tries that
///    network photo first and, only if it fails to load (offline, endpoint
///    hiccup, no key configured, etc.), falls back to a bundled local
///    placeholder chosen from [tags]/[category]/name keywords, so the UI
///    never shows a broken image.
///
/// Centralizing this logic means the image source can be swapped later
/// (e.g. a different photo API, or real AI image generation once a paid key
/// is available) by editing only this file.
class RecipeImageResolver {
  RecipeImageResolver._();

  static const String _basePath = 'assets/images';

  /// In-memory cache from search phrase -> resolved photo URL (or null if
  /// the search came back empty), so re-rendering the same recipe/session
  /// never re-hits the network or the Unsplash rate limit for a query
  /// that's already been resolved once.
  static final Map<String, String?> _cache = {};

  /// Searches Unsplash for a real photo matching [query] and returns a
  /// ready-to-display image URL, or an empty string if nothing usable came
  /// back (no API key configured, offline, no results, request failed).
  /// [FallbackImage] treats an empty string exactly like "no network URL"
  /// and shows the local placeholder instead — this method never throws.
  ///
  /// [accessKey] defaults to [UnsplashConfig.accessKey] (the real
  /// build-time key). Tests pass a fake key here directly, since
  /// `String.fromEnvironment` is fixed at compile time and `flutter test`
  /// doesn't receive the `--dart-define` the real app is built with.
  static Future<String> urlForQuery(
    String query, {
    http.Client? client,
    String accessKey = UnsplashConfig.accessKey,
  }) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return '';
    if (accessKey.isEmpty) return '';

    if (_cache.containsKey(cleaned)) {
      return _cache[cleaned] ?? '';
    }

    final ownClient = client == null;
    final httpClient = client ?? http.Client();
    try {
      final uri = Uri.parse(UnsplashConfig.searchPhotosEndpoint).replace(
        queryParameters: {
          'query': cleaned,
          'per_page': '1',
          'orientation': 'landscape',
        },
      );

      final response = await httpClient
          .get(uri, headers: {'Authorization': 'Client-ID $accessKey'})
          .timeout(UnsplashConfig.requestTimeout);

      if (response.statusCode != 200) {
        _cache[cleaned] = null;
        return '';
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['results'] is! List) {
        _cache[cleaned] = null;
        return '';
      }

      final results = decoded['results'] as List;
      if (results.isEmpty) {
        _cache[cleaned] = null;
        return '';
      }

      final first = results.first;
      if (first is! Map) {
        _cache[cleaned] = null;
        return '';
      }

      final urls = first['urls'];
      final url = (urls is Map ? urls['regular'] ?? urls['small'] : null) as String?;
      _cache[cleaned] = url;
      return url ?? '';
    } catch (_) {
      // Network error, timeout, malformed JSON, etc. — never let a bad
      // photo lookup break recipe generation; just fall back silently.
      return '';
    } finally {
      if (ownClient) httpClient.close();
    }
  }

  /// The real-photo URL for a given [Recipe], derived from its AI-provided
  /// [Recipe.imageQuery] (falling back to the title if that's empty).
  /// Returns an empty string if there's nothing usable to search for or
  /// the lookup fails, in which case [FallbackImage] skips straight to the
  /// local placeholder.
  static Future<String> urlForRecipe(
    Recipe recipe, {
    http.Client? client,
    String accessKey = UnsplashConfig.accessKey,
  }) {
    final query = (recipe.imageQuery?.trim().isNotEmpty ?? false) ? recipe.imageQuery!.trim() : recipe.title;
    return urlForQuery(query, client: client, accessKey: accessKey);
  }

  /// Bundled recipe/category placeholders. Keys are matched against the
  /// recipe title/tags; falls back to [_defaultRecipeImage] if nothing
  /// matches.
  static const Map<String, String> _recipeKeywordImages = {
    'breakfast': '$_basePath/placeholder_breakfast.png',
    'pancake': '$_basePath/placeholder_breakfast.png',
    'egg': '$_basePath/placeholder_breakfast.png',
    'salad': '$_basePath/placeholder_salad.png',
    'soup': '$_basePath/placeholder_soup.png',
    'stew': '$_basePath/placeholder_soup.png',
    'pasta': '$_basePath/placeholder_pasta.png',
    'noodle': '$_basePath/placeholder_pasta.png',
    'rice': '$_basePath/placeholder_rice.png',
    'chicken': '$_basePath/placeholder_chicken.png',
    'beef': '$_basePath/placeholder_meat.png',
    'meat': '$_basePath/placeholder_meat.png',
    'fish': '$_basePath/placeholder_fish.png',
    'seafood': '$_basePath/placeholder_fish.png',
    'dessert': '$_basePath/placeholder_dessert.png',
    'cake': '$_basePath/placeholder_dessert.png',
    'sweet': '$_basePath/placeholder_dessert.png',
    'sandwich': '$_basePath/placeholder_sandwich.png',
    'toast': '$_basePath/placeholder_sandwich.png',
    'vegetarian': '$_basePath/placeholder_vegetarian.png',
    'vegetable': '$_basePath/placeholder_vegetarian.png',
  };

  static const String _defaultRecipeImage = '$_basePath/placeholder_recipe.png';

  static const Map<IngredientCategory, String> _categoryImages = {
    IngredientCategory.vegetables: '$_basePath/placeholder_vegetables.png',
    IngredientCategory.meat: '$_basePath/placeholder_meat.png',
    IngredientCategory.dairy: '$_basePath/placeholder_dairy.png',
    IngredientCategory.fruits: '$_basePath/placeholder_fruits.png',
    IngredientCategory.grains: '$_basePath/placeholder_grains.png',
    IngredientCategory.pantry: '$_basePath/placeholder_pantry.png',
  };

  static const String onboardingHero1 = '$_basePath/onboarding_scan.png';
  static const String onboardingHero2 = '$_basePath/onboarding_ingredients.png';
  static const String onboardingHero3 = '$_basePath/onboarding_recipes.png';
  static const String scannerFallback = '$_basePath/placeholder_recipe.png';

  /// Best-effort local asset path for a recipe based on its title and tags.
  static String assetForRecipe(Recipe recipe) {
    final haystack = ('${recipe.title} ${recipe.tags.map((t) => t.name).join(' ')}').toLowerCase();
    for (final entry in _recipeKeywordImages.entries) {
      if (haystack.contains(entry.key)) return entry.value;
    }
    return _defaultRecipeImage;
  }

  /// Local asset path for a pantry ingredient based on its category.
  static String assetForIngredient(Ingredient ingredient) {
    return _categoryImages[ingredient.category] ?? _defaultRecipeImage;
  }

  static String assetForCategory(IngredientCategory category) {
    return _categoryImages[category] ?? _defaultRecipeImage;
  }

  /// The real-photo URL for a given [Ingredient], searched by its own name
  /// (e.g. "chicken breast", "red onion") rather than its broad category —
  /// so each pantry item gets a distinct, recognizable photo instead of one
  /// shared per-category placeholder. Falls back to the category name if
  /// the ingredient name is somehow empty. Returns an empty string if
  /// nothing usable comes back, in which case [FallbackImage] shows the
  /// bundled category placeholder instead.
  static Future<String> urlForIngredient(
    Ingredient ingredient, {
    http.Client? client,
    String accessKey = UnsplashConfig.accessKey,
  }) {
    final query = (ingredient.imageQuery?.trim().isNotEmpty ?? false)
        ? ingredient.imageQuery!.trim()
        : (ingredient.name.trim().isNotEmpty ? ingredient.name.trim() : ingredient.category.label);
    return urlForQuery(query, client: client, accessKey: accessKey);
  }
}
