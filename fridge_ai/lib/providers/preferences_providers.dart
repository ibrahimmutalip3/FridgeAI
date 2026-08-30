import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_preferences.dart';
import 'core_providers.dart';

/// Holds the current [UserPreferences], seeded synchronously from local
/// storage on creation (SharedPreferences reads are synchronous once
/// initialized in `main()`, so no loading state is needed here).
class PreferencesNotifier extends StateNotifier<UserPreferences> {
  PreferencesNotifier(this._ref) : super(_ref.read(preferencesRepositoryProvider).get());

  final Ref _ref;

  Future<void> update(UserPreferences Function(UserPreferences current) updater) async {
    final updated = updater(state);
    state = updated;
    await _ref.read(preferencesRepositoryProvider).save(updated);
  }

  Future<void> setThemeMode(AppThemeMode mode) => update((p) => p.copyWith(themeMode: mode));

  Future<void> setUserName(String name) => update((p) => p.copyWith(userName: name));

  Future<void> setServingSize(int size) => update((p) => p.copyWith(servingSize: size));

  Future<void> setDietaryPreferences(List<String> values) =>
      update((p) => p.copyWith(dietaryPreferences: values));

  Future<void> setAllergies(List<String> values) => update((p) => p.copyWith(allergies: values));

  Future<void> setFavoriteCuisines(List<String> values) =>
      update((p) => p.copyWith(favoriteCuisines: values));

  Future<void> setNotificationsEnabled(bool enabled) =>
      update((p) => p.copyWith(notificationsEnabled: enabled));

  Future<void> completeOnboarding() async {
    await _ref.read(preferencesRepositoryProvider).completeOnboarding();
    state = state.copyWith(onboardingComplete: true);
  }
}

final preferencesProvider = StateNotifierProvider<PreferencesNotifier, UserPreferences>(
  (ref) => PreferencesNotifier(ref),
);

final userStatsProvider = Provider.autoDispose<UserStats>((ref) {
  return ref.watch(preferencesRepositoryProvider).getStats();
});
