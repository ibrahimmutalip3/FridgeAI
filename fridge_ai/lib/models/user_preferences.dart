import 'package:equatable/equatable.dart';

enum AppThemeMode {
  light,
  dark,
  system;

  static AppThemeMode fromString(String? value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }
}

/// User-configurable preferences persisted locally.
class UserPreferences extends Equatable {
  final String userName;
  final AppThemeMode themeMode;
  final bool notificationsEnabled;
  final int servingSize;
  final List<String> dietaryPreferences;
  final List<String> allergies;
  final List<String> favoriteCuisines;
  final bool onboardingComplete;

  const UserPreferences({
    this.userName = 'Chef',
    this.themeMode = AppThemeMode.system,
    this.notificationsEnabled = true,
    this.servingSize = 2,
    this.dietaryPreferences = const [],
    this.allergies = const [],
    this.favoriteCuisines = const [],
    this.onboardingComplete = false,
  });

  UserPreferences copyWith({
    String? userName,
    AppThemeMode? themeMode,
    bool? notificationsEnabled,
    int? servingSize,
    List<String>? dietaryPreferences,
    List<String>? allergies,
    List<String>? favoriteCuisines,
    bool? onboardingComplete,
  }) {
    return UserPreferences(
      userName: userName ?? this.userName,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      servingSize: servingSize ?? this.servingSize,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      allergies: allergies ?? this.allergies,
      favoriteCuisines: favoriteCuisines ?? this.favoriteCuisines,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  @override
  List<Object?> get props => [
        userName,
        themeMode,
        notificationsEnabled,
        servingSize,
        dietaryPreferences,
        allergies,
        favoriteCuisines,
        onboardingComplete,
      ];
}

/// Simple cooking statistics tracked for the Profile screen.
class UserStats extends Equatable {
  final int recipesCooked;
  final int ingredientsScanned;
  final int favoritesCount;

  const UserStats({
    this.recipesCooked = 0,
    this.ingredientsScanned = 0,
    this.favoritesCount = 0,
  });

  UserStats copyWith({
    int? recipesCooked,
    int? ingredientsScanned,
    int? favoritesCount,
  }) {
    return UserStats(
      recipesCooked: recipesCooked ?? this.recipesCooked,
      ingredientsScanned: ingredientsScanned ?? this.ingredientsScanned,
      favoritesCount: favoritesCount ?? this.favoritesCount,
    );
  }

  @override
  List<Object?> get props => [recipesCooked, ingredientsScanned, favoritesCount];
}
