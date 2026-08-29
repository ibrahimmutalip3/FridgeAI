import '../models/user_preferences.dart';
import '../services/storage_service.dart';

/// Repository for user preferences, onboarding state, and cooking stats.
class PreferencesRepository {
  PreferencesRepository({StorageService? storage}) : _storage = storage ?? StorageService.instance;

  final StorageService _storage;

  UserPreferences get() => _storage.getPreferences();

  Future<void> save(UserPreferences preferences) => _storage.savePreferences(preferences);

  Future<void> completeOnboarding() => _storage.setOnboardingComplete(true);

  UserStats getStats() {
    return UserStats(
      recipesCooked: _storage.getRecipesCooked(),
      ingredientsScanned: _storage.getIngredientsScanned(),
      favoritesCount: _storage.getFavoriteRecipes().length,
    );
  }
}
