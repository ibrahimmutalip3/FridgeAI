import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/pantry_repository.dart';
import '../repositories/preferences_repository.dart';
import '../repositories/recipe_repository.dart';
import '../repositories/scan_repository.dart';
import '../services/image_service.dart';

/// Repositories are provided as simple singletons — they hold no widget
/// state themselves, just wrap services. This keeps the dependency graph
/// easy to override in tests (e.g. `pantryRepositoryProvider.overrideWithValue`).
final pantryRepositoryProvider = Provider<PantryRepository>((ref) => PantryRepository());

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final repo = RecipeRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  final repo = ScanRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) => PreferencesRepository());

final imageServiceProvider = Provider<ImageService>((ref) => ImageService());
