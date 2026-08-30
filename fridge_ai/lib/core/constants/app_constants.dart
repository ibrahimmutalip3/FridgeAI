/// Centralized, non-visual app-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'FridgeAI';

  // Hive box names
  static const String pantryBoxName = 'pantry_box';
  static const String favoritesBoxName = 'favorites_box';
  static const String recentlyViewedBoxName = 'recently_viewed_box';
  static const String preferencesBoxName = 'preferences_box';
  static const String statsBoxName = 'stats_box';

  // SharedPreferences keys
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefOnboardingComplete = 'pref_onboarding_complete';
  static const String prefNotificationsEnabled = 'pref_notifications_enabled';
  static const String prefServingSize = 'pref_serving_size';
  static const String prefDietaryPreferences = 'pref_dietary_preferences';
  static const String prefAllergies = 'pref_allergies';
  static const String prefFavoriteCuisines = 'pref_favorite_cuisines';
  static const String prefUserName = 'pref_user_name';
  static const String prefAvatarPath = 'pref_avatar_path';
  static const String prefRecipesCooked = 'pref_recipes_cooked';
  static const String prefIngredientsScanned = 'pref_ingredients_scanned';

  // Limits
  static const int maxRecentlyViewed = 20;
  static const int maxRecipeSuggestions = 6;
  static const double defaultBorderRadius = 24.0;
  static const double smallBorderRadius = 16.0;
  static const double largeBorderRadius = 32.0;
}
