import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/app_failure.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/user_preferences.dart';

/// Thin, reliable local-storage layer.
///
/// - Hive boxes store structured/collection data (pantry ingredients,
///   favorite recipes, recently viewed recipes) as plain JSON maps, so no
///   generated type adapters are needed — keeps the build simple and
///   avoids a build_runner step in CI.
/// - SharedPreferences stores small scalar preferences (theme, onboarding
///   completion, stats counters).
///
/// Every method that can fail converts the underlying exception into an
/// [AppFailure] so the UI never sees a raw Hive/platform exception.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  Box<Map>? _pantryBox;
  Box<Map>? _favoritesBox;
  Box<Map>? _recentlyViewedBox;
  SharedPreferences? _prefs;

  bool _initialized = false;

  /// Must be called once before any other method (typically in `main()`
  /// before `runApp`).
  Future<void> init() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      _pantryBox = await Hive.openBox<Map>(AppConstants.pantryBoxName);
      _favoritesBox = await Hive.openBox<Map>(AppConstants.favoritesBoxName);
      _recentlyViewedBox = await Hive.openBox<Map>(AppConstants.recentlyViewedBoxName);
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  Box<Map> get _pantry => _requireBox(_pantryBox);
  Box<Map> get _favorites => _requireBox(_favoritesBox);
  Box<Map> get _recentlyViewed => _requireBox(_recentlyViewedBox);
  SharedPreferences get _preferences => _prefs ?? (throw AppFailure.storage());

  Box<Map> _requireBox(Box<Map>? box) {
    if (box == null) throw AppFailure.storage();
    return box;
  }

  // ---------------------------------------------------------------------
  // Pantry (My Kitchen)
  // ---------------------------------------------------------------------

  List<Ingredient> getPantryIngredients() {
    try {
      return _pantry.values
          .map((raw) => Ingredient.fromJson(Map<String, dynamic>.from(raw)))
          .toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  Future<void> savePantryIngredient(Ingredient ingredient) async {
    try {
      await _pantry.put(ingredient.id, ingredient.toJson());
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  Future<void> savePantryIngredients(List<Ingredient> ingredients) async {
    try {
      final entries = {for (final i in ingredients) i.id: i.toJson()};
      await _pantry.putAll(entries);
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  Future<void> deletePantryIngredient(String id) async {
    try {
      await _pantry.delete(id);
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  Future<void> clearPantry() async {
    try {
      await _pantry.clear();
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  // ---------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------

  List<Recipe> getFavoriteRecipes() {
    try {
      return _favorites.values
          .map((raw) => Recipe.fromJson(Map<String, dynamic>.from(raw)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  bool isFavorite(String recipeId) => _favorites.containsKey(recipeId);

  Future<void> toggleFavorite(Recipe recipe) async {
    try {
      if (_favorites.containsKey(recipe.id)) {
        await _favorites.delete(recipe.id);
      } else {
        await _favorites.put(recipe.id, recipe.toJson());
      }
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  // ---------------------------------------------------------------------
  // Recently viewed
  // ---------------------------------------------------------------------

  List<Recipe> getRecentlyViewed() {
    try {
      final recipes = _recentlyViewed.values
          .map((raw) => Recipe.fromJson(Map<String, dynamic>.from(raw)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return recipes;
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  Future<void> recordRecentlyViewed(Recipe recipe) async {
    try {
      await _recentlyViewed.put(recipe.id, recipe.toJson());
      if (_recentlyViewed.length > AppConstants.maxRecentlyViewed) {
        final sortedKeys = _recentlyViewed.toMap().entries.toList()
          ..sort((a, b) {
            final aTime = DateTime.tryParse((a.value['createdAt'] ?? '') as String) ?? DateTime.now();
            final bTime = DateTime.tryParse((b.value['createdAt'] ?? '') as String) ?? DateTime.now();
            return aTime.compareTo(bTime);
          });
        final excess = _recentlyViewed.length - AppConstants.maxRecentlyViewed;
        for (var i = 0; i < excess; i++) {
          await _recentlyViewed.delete(sortedKeys[i].key);
        }
      }
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  // ---------------------------------------------------------------------
  // Preferences
  // ---------------------------------------------------------------------

  UserPreferences getPreferences() {
    final prefs = _preferences;
    return UserPreferences(
      userName: prefs.getString(AppConstants.prefUserName) ?? 'Chef',
      themeMode: AppThemeMode.fromString(prefs.getString(AppConstants.prefThemeMode)),
      notificationsEnabled: prefs.getBool(AppConstants.prefNotificationsEnabled) ?? true,
      servingSize: prefs.getInt(AppConstants.prefServingSize) ?? 2,
      dietaryPreferences: prefs.getStringList(AppConstants.prefDietaryPreferences) ?? const [],
      allergies: prefs.getStringList(AppConstants.prefAllergies) ?? const [],
      favoriteCuisines: prefs.getStringList(AppConstants.prefFavoriteCuisines) ?? const [],
      onboardingComplete: prefs.getBool(AppConstants.prefOnboardingComplete) ?? false,
    );
  }

  Future<void> savePreferences(UserPreferences preferences) async {
    try {
      final prefs = _preferences;
      await prefs.setString(AppConstants.prefUserName, preferences.userName);
      await prefs.setString(AppConstants.prefThemeMode, preferences.themeMode.name);
      await prefs.setBool(AppConstants.prefNotificationsEnabled, preferences.notificationsEnabled);
      await prefs.setInt(AppConstants.prefServingSize, preferences.servingSize);
      await prefs.setStringList(AppConstants.prefDietaryPreferences, preferences.dietaryPreferences);
      await prefs.setStringList(AppConstants.prefAllergies, preferences.allergies);
      await prefs.setStringList(AppConstants.prefFavoriteCuisines, preferences.favoriteCuisines);
      await prefs.setBool(AppConstants.prefOnboardingComplete, preferences.onboardingComplete);
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  Future<void> setOnboardingComplete(bool complete) async {
    try {
      await _preferences.setBool(AppConstants.prefOnboardingComplete, complete);
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  // ---------------------------------------------------------------------
  // Stats
  // ---------------------------------------------------------------------

  int getRecipesCooked() => _preferences.getInt(AppConstants.prefRecipesCooked) ?? 0;
  int getIngredientsScanned() => _preferences.getInt(AppConstants.prefIngredientsScanned) ?? 0;

  Future<void> incrementRecipesCooked() async {
    try {
      final current = getRecipesCooked();
      await _preferences.setInt(AppConstants.prefRecipesCooked, current + 1);
    } catch (_) {
      throw AppFailure.storage();
    }
  }

  Future<void> incrementIngredientsScanned(int count) async {
    try {
      final current = getIngredientsScanned();
      await _preferences.setInt(AppConstants.prefIngredientsScanned, current + count);
    } catch (_) {
      throw AppFailure.storage();
    }
  }
}
