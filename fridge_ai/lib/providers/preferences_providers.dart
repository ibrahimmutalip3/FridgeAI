import 'dart:io';

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

  /// Copies [source] into the app's local storage (so it survives restarts
  /// and isn't lost if the OS clears the picker's temp cache) and sets it
  /// as the user's avatar, replacing any previous avatar file.
  Future<void> setAvatar(File source) async {
    final savedPath = await _ref
        .read(imageServiceProvider)
        .saveAvatarLocally(source, previousPath: state.avatarPath);
    await update((p) => p.copyWith(avatarPath: savedPath));
  }

  /// Removes the current avatar, deleting its local file and reverting to
  /// the default initial-letter avatar.
  Future<void> clearAvatar() async {
    final currentPath = state.avatarPath;
    if (currentPath != null) {
      await _ref.read(imageServiceProvider).deleteAvatar(currentPath);
    }
    await update((p) => p.copyWith(clearAvatarPath: true));
  }

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
