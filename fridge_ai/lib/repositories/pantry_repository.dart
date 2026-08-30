import '../models/ingredient.dart';
import '../services/storage_service.dart';

/// Repository for the user's pantry (persisted ingredients across the
/// app — "My Kitchen"). Wraps [StorageService] so features/providers never
/// talk to Hive directly, keeping the storage backend swappable.
class PantryRepository {
  PantryRepository({StorageService? storage}) : _storage = storage ?? StorageService.instance;

  final StorageService _storage;

  List<Ingredient> getAll() => _storage.getPantryIngredients();

  Map<IngredientCategory, List<Ingredient>> getGroupedByCategory() {
    final all = getAll();
    final grouped = <IngredientCategory, List<Ingredient>>{
      for (final category in IngredientCategory.values) category: [],
    };
    for (final ingredient in all) {
      grouped[ingredient.category]!.add(ingredient);
    }
    return grouped;
  }

  Future<void> add(Ingredient ingredient) => _storage.savePantryIngredient(ingredient);

  Future<void> addAll(List<Ingredient> ingredients) => _storage.savePantryIngredients(ingredients);

  Future<void> update(Ingredient ingredient) => _storage.savePantryIngredient(ingredient);

  Future<void> remove(String id) => _storage.deletePantryIngredient(id);

  Future<void> clear() => _storage.clearPantry();
}
