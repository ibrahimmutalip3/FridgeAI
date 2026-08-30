import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_ai/core/constants/app_constants.dart';
import 'package:fridge_ai/models/user_preferences.dart';

void main() {
  group('AppThemeMode.fromString', () {
    test('parses known values', () {
      expect(AppThemeMode.fromString('light'), AppThemeMode.light);
      expect(AppThemeMode.fromString('dark'), AppThemeMode.dark);
      expect(AppThemeMode.fromString('system'), AppThemeMode.system);
    });

    test('defaults to system for null or unrecognized values', () {
      expect(AppThemeMode.fromString(null), AppThemeMode.system);
      expect(AppThemeMode.fromString('sepia'), AppThemeMode.system);
    });
  });

  group('UserPreferences', () {
    test('has sensible defaults', () {
      const prefs = UserPreferences();
      expect(prefs.userName, 'Chef');
      expect(prefs.avatarPath, isNull);
      expect(prefs.themeMode, AppThemeMode.system);
      expect(prefs.notificationsEnabled, isTrue);
      expect(prefs.servingSize, 2);
      expect(prefs.onboardingComplete, isFalse);
      expect(prefs.dietaryPreferences, isEmpty);
    });

    test('copyWith updates only the requested fields', () {
      const original = UserPreferences(userName: 'Alex', servingSize: 2);
      final updated = original.copyWith(servingSize: 4, onboardingComplete: true);

      expect(updated.userName, 'Alex');
      expect(updated.servingSize, 4);
      expect(updated.onboardingComplete, isTrue);
      // Untouched fields stay the same instance's values.
      expect(updated.themeMode, original.themeMode);
    });

    test('copyWith sets avatarPath', () {
      const original = UserPreferences();
      final updated = original.copyWith(avatarPath: '/data/avatars/me.jpg');
      expect(updated.avatarPath, '/data/avatars/me.jpg');
    });

    test('copyWith clearAvatarPath removes an existing avatar', () {
      const original = UserPreferences(avatarPath: '/data/avatars/me.jpg');
      final updated = original.copyWith(clearAvatarPath: true);
      expect(updated.avatarPath, isNull);
    });

    test('two instances with the same values are equal (Equatable)', () {
      const a = UserPreferences(userName: 'Sam', servingSize: 3);
      const b = UserPreferences(userName: 'Sam', servingSize: 3);
      expect(a, equals(b));
    });
  });

  group('UserStats', () {
    test('copyWith updates only the requested fields', () {
      const stats = UserStats(recipesCooked: 5, ingredientsScanned: 10, favoritesCount: 2);
      final updated = stats.copyWith(recipesCooked: 6);

      expect(updated.recipesCooked, 6);
      expect(updated.ingredientsScanned, 10);
      expect(updated.favoritesCount, 2);
    });
  });

  group('AppConstants', () {
    test('all SharedPreferences keys are unique', () {
      final keys = [
        AppConstants.prefThemeMode,
        AppConstants.prefOnboardingComplete,
        AppConstants.prefNotificationsEnabled,
        AppConstants.prefServingSize,
        AppConstants.prefDietaryPreferences,
        AppConstants.prefAllergies,
        AppConstants.prefFavoriteCuisines,
        AppConstants.prefUserName,
        AppConstants.prefAvatarPath,
        AppConstants.prefRecipesCooked,
        AppConstants.prefIngredientsScanned,
      ];
      expect(keys.toSet().length, keys.length, reason: 'Duplicate SharedPreferences key would silently overwrite data');
    });

    test('all Hive box names are unique', () {
      final boxes = [
        AppConstants.pantryBoxName,
        AppConstants.favoritesBoxName,
        AppConstants.recentlyViewedBoxName,
        AppConstants.preferencesBoxName,
        AppConstants.statsBoxName,
      ];
      expect(boxes.toSet().length, boxes.length, reason: 'Duplicate Hive box name would corrupt unrelated data');
    });
  });
}
