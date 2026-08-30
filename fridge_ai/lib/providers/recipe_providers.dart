import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_failure.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import 'core_providers.dart';
import 'pantry_providers.dart';
import 'preferences_providers.dart';

enum RecipeGenerationStatus { idle, loading, success, empty, error }

class RecipeGenerationState {
  final RecipeGenerationStatus status;
  final List<Recipe> recipes;
  final String? errorMessage;

  const RecipeGenerationState({
    this.status = RecipeGenerationStatus.idle,
    this.recipes = const [],
    this.errorMessage,
  });

  RecipeGenerationState copyWith({
    RecipeGenerationStatus? status,
    List<Recipe>? recipes,
    String? errorMessage,
  }) {
    return RecipeGenerationState(
      status: status ?? this.status,
      recipes: recipes ?? this.recipes,
      errorMessage: errorMessage,
    );
  }
}

/// Drives AI recipe generation from the currently confirmed ingredient
/// list (pantry, or scan draft depending on entry point).
class RecipeGenerationNotifier extends StateNotifier<RecipeGenerationState> {
  RecipeGenerationNotifier(this._ref) : super(const RecipeGenerationState());

  final Ref _ref;

  Future<void> generate(List<Ingredient> ingredients) async {
    state = state.copyWith(status: RecipeGenerationStatus.loading, errorMessage: null);
    try {
      final preferences = _ref.read(preferencesProvider);
      final recipes = await _ref.read(recipeRepositoryProvider).generateRecipes(
            ingredients: ingredients,
            preferences: preferences,
          );
      if (recipes.isEmpty) {
        state = state.copyWith(status: RecipeGenerationStatus.empty, recipes: const []);
        return;
      }
      state = state.copyWith(status: RecipeGenerationStatus.success, recipes: recipes);
    } on AppFailure catch (e) {
      state = state.copyWith(status: RecipeGenerationStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: RecipeGenerationStatus.error,
        errorMessage: AppFailure.generic().message,
      );
    }
  }

  void reset() => state = const RecipeGenerationState();
}

final recipeGenerationProvider =
    StateNotifierProvider<RecipeGenerationNotifier, RecipeGenerationState>(
  (ref) => RecipeGenerationNotifier(ref),
);

/// Filter chips shown on the Recipe Results / Recipes screens.
final recipeFilterProvider = StateProvider.autoDispose<RecipeTag?>((ref) => null);

final filteredRecipesProvider = Provider.autoDispose<List<Recipe>>((ref) {
  final recipes = ref.watch(recipeGenerationProvider).recipes;
  final filter = ref.watch(recipeFilterProvider);
  if (filter == null) return recipes;
  return recipes.where((r) => r.tags.contains(filter)).toList();
});

/// Favorites — a simple refresh-counter pattern keeps this provider
/// trivial to invalidate after a toggle without needing async streams.
final _favoritesRefreshProvider = StateProvider<int>((ref) => 0);

final favoriteRecipesProvider = Provider.autoDispose<List<Recipe>>((ref) {
  ref.watch(_favoritesRefreshProvider);
  return ref.watch(recipeRepositoryProvider).getFavorites();
});

final recentlyViewedProvider = Provider.autoDispose<List<Recipe>>((ref) {
  ref.watch(_favoritesRefreshProvider);
  return ref.watch(recipeRepositoryProvider).getRecentlyViewed();
});

class FavoritesController {
  FavoritesController(this._ref);
  final Ref _ref;

  bool isFavorite(String recipeId) => _ref.read(recipeRepositoryProvider).isFavorite(recipeId);

  Future<void> toggle(Recipe recipe) async {
    await _ref.read(recipeRepositoryProvider).toggleFavorite(recipe);
    _ref.read(_favoritesRefreshProvider.notifier).state++;
  }

  Future<void> recordViewed(Recipe recipe) async {
    await _ref.read(recipeRepositoryProvider).recordRecentlyViewed(recipe);
    _ref.read(_favoritesRefreshProvider.notifier).state++;
  }

  Future<void> markCooked() async {
    await _ref.read(recipeRepositoryProvider).markCooked();
  }
}

final favoritesControllerProvider = Provider<FavoritesController>((ref) => FavoritesController(ref));

/// Convenience: recipes generated using the full persisted pantry
/// ("Recommended for you" on Home, "Based on your ingredients" on Recipes).
final pantryBasedRecipesProvider = Provider.autoDispose<List<Recipe>>((ref) {
  ref.watch(pantryProvider);
  return ref.watch(recipeGenerationProvider).recipes;
});
