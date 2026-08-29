import '../models/ingredient.dart';
import '../models/recipe.dart';

/// FridgeAI has no custom backend and no paid image-generation API key, so
/// this resolver is the single source of truth for turning a [Recipe] or
/// [Ingredient] into a concrete image reference:
///
///  - Every recipe gets a real-photo [networkUrlForQuery] built from the
///    short image search phrase the AI returns alongside the recipe
///    (`recipe.imageQuery`, e.g. "creamy chicken rice bowl"). This is
///    resolved through Unsplash Source, a keyless endpoint that redirects a
///    plain search phrase straight to a matching real photo — no API key,
///    no account, no backend of ours involved.
///  - `FallbackImage` (see core/widgets/fallback_image.dart) tries that
///    network photo first and, only if it fails to load (offline, endpoint
///    hiccup, etc.), falls back to a bundled local placeholder chosen from
///    [tags]/[category]/name keywords, so the UI never shows a broken image.
///
/// Centralizing this logic means the image source can be swapped later
/// (e.g. a different photo API, or real AI image generation once a paid key
/// is available) by editing only this file.
class RecipeImageResolver {
  RecipeImageResolver._();

  static const String _basePath = 'assets/images';

  // Keyless real-photo endpoint. Appending a plain-text query redirects to a
  // matching photo — e.g. https://source.unsplash.com/800x600/?pasta,tomato.
  // No account or API key required, which fits this project's "no backend,
  // no secrets beyond GROQ_API_KEY" constraint.
  static const String _unsplashSourceBase = 'https://source.unsplash.com';

  /// Builds a real-photo URL for a short search phrase (spaces become
  /// commas, since Unsplash Source treats commas as separate search terms
  /// and ANDs them together for a more specific match). A [seed] keeps the
  /// same recipe pinned to the same photo across rebuilds instead of a new
  /// random one on every request, while still varying between recipes that
  /// share a query.
  static String networkUrlForQuery(String query, {String? seed}) {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return '';
    final terms = cleaned
        .toLowerCase()
        .split(RegExp(r'[\s,]+'))
        .where((t) => t.isNotEmpty)
        .take(4)
        .join(',');
    final sig = seed != null && seed.isNotEmpty ? '&sig=${seed.hashCode}' : '';
    return '$_unsplashSourceBase/800x600/?$terms$sig';
  }

  /// The real-photo URL for a given [Recipe], derived from its AI-provided
  /// [Recipe.imageQuery] (falling back to the title if that's empty).
  /// Returns an empty string if there's nothing usable to search for, in
  /// which case [FallbackImage] skips straight to the local placeholder.
  static String networkUrlForRecipe(Recipe recipe) {
    final query = (recipe.imageQuery?.trim().isNotEmpty ?? false) ? recipe.imageQuery!.trim() : recipe.title;
    return networkUrlForQuery(query, seed: recipe.id);
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
}
