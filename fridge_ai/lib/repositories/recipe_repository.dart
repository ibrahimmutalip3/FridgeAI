import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/user_preferences.dart';
import '../services/groq_service.dart';
import '../services/storage_service.dart';

/// Repository that orchestrates recipe generation (via Groq) and recipe
/// persistence (favorites, recently viewed) via [StorageService]. Features
/// depend on this rather than talking to Groq or Hive directly.
class RecipeRepository {
  RecipeRepository({GroqService? groqService, StorageService? storage})
      : _groqService = groqService ?? GroqService(),
        _storage = storage ?? StorageService.instance;

  final GroqService _groqService;
  final StorageService _storage;

  Future<List<Recipe>> generateRecipes({
    required List<Ingredient> ingredients,
    UserPreferences? preferences,
  }) {
    return _groqService.generateRecipes(
      ingredients: ingredients,
      dietaryPreferences: preferences?.dietaryPreferences ?? const [],
      allergies: preferences?.allergies ?? const [],
      favoriteCuisines: preferences?.favoriteCuisines ?? const [],
      servings: preferences?.servingSize ?? 2,
    );
  }

  List<Recipe> getFavorites() => _storage.getFavoriteRecipes();

  bool isFavorite(String recipeId) => _storage.isFavorite(recipeId);

  Future<void> toggleFavorite(Recipe recipe) => _storage.toggleFavorite(recipe);

  List<Recipe> getRecentlyViewed() => _storage.getRecentlyViewed();

  Future<void> recordRecentlyViewed(Recipe recipe) => _storage.recordRecentlyViewed(recipe);

  Future<void> markCooked() => _storage.incrementRecipesCooked();

  void dispose() => _groqService.dispose();
}
