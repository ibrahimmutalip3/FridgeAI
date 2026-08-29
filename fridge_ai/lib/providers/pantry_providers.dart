import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_failure.dart';
import '../models/ingredient.dart';
import 'core_providers.dart';

/// Holds the user's full pantry ingredient list, loaded from local storage.
/// All mutations go through this notifier so every screen watching pantry
/// state (Home, My Kitchen, Ingredient Results) stays in sync.
class PantryNotifier extends StateNotifier<List<Ingredient>> {
  PantryNotifier(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  void _load() {
    try {
      state = _ref.read(pantryRepositoryProvider).getAll();
    } catch (_) {
      state = const [];
    }
  }

  Future<void> addIngredient(Ingredient ingredient) async {
    await _ref.read(pantryRepositoryProvider).add(ingredient);
    state = [ingredient, ...state];
  }

  Future<void> addIngredients(List<Ingredient> ingredients) async {
    if (ingredients.isEmpty) return;
    await _ref.read(pantryRepositoryProvider).addAll(ingredients);
    state = [...ingredients, ...state];
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    await _ref.read(pantryRepositoryProvider).update(ingredient);
    state = [
      for (final existing in state)
        if (existing.id == ingredient.id) ingredient else existing,
    ];
  }

  Future<void> removeIngredient(String id) async {
    await _ref.read(pantryRepositoryProvider).remove(id);
    state = state.where((i) => i.id != id).toList();
  }

  Future<void> clearAll() async {
    await _ref.read(pantryRepositoryProvider).clear();
    state = const [];
  }

  void refresh() => _load();
}

final pantryProvider = StateNotifierProvider<PantryNotifier, List<Ingredient>>(
  (ref) => PantryNotifier(ref),
);

final pantryGroupedProvider = Provider.autoDispose<Map<IngredientCategory, List<Ingredient>>>((ref) {
  final ingredients = ref.watch(pantryProvider);
  final grouped = <IngredientCategory, List<Ingredient>>{
    for (final category in IngredientCategory.values) category: [],
  };
  for (final ingredient in ingredients) {
    grouped[ingredient.category]!.add(ingredient);
  }
  return grouped;
});

/// Working, in-memory list of ingredients detected during the current
/// scan session (Scanner -> AI Analysis -> Ingredient Results -> Confirm),
/// before the user confirms and they are merged into the persisted pantry.
class ScanDraftNotifier extends StateNotifier<List<Ingredient>> {
  ScanDraftNotifier() : super(const []);

  void setAll(List<Ingredient> ingredients) => state = ingredients;

  void add(Ingredient ingredient) => state = [...state, ingredient];

  void update(Ingredient ingredient) {
    state = [
      for (final existing in state)
        if (existing.id == ingredient.id) ingredient else existing,
    ];
  }

  void remove(String id) => state = state.where((i) => i.id != id).toList();

  void clear() => state = const [];
}

final scanDraftProvider = StateNotifierProvider<ScanDraftNotifier, List<Ingredient>>(
  (ref) => ScanDraftNotifier(),
);

enum ScanFlowStatus { idle, capturing, analyzing, success, noFoodDetected, error }

class ScanFlowState {
  final ScanFlowStatus status;
  final String? errorMessage;

  const ScanFlowState({this.status = ScanFlowStatus.idle, this.errorMessage});

  ScanFlowState copyWith({ScanFlowStatus? status, String? errorMessage}) {
    return ScanFlowState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

/// Drives the Scanner -> AI Analysis screen transition and error state.
class ScanFlowNotifier extends StateNotifier<ScanFlowState> {
  ScanFlowNotifier(this._ref) : super(const ScanFlowState());

  final Ref _ref;

  Future<void> analyze(dynamic imageFile) async {
    state = state.copyWith(status: ScanFlowStatus.analyzing, errorMessage: null);
    try {
      final result = await _ref.read(scanRepositoryProvider).analyzeImage(imageFile);
      if (!result.success || result.ingredients.isEmpty) {
        state = state.copyWith(
          status: ScanFlowStatus.noFoodDetected,
          errorMessage: result.errorMessage ?? AppFailure.noFoodDetected().message,
        );
        return;
      }
      _ref.read(scanDraftProvider.notifier).setAll(result.ingredients);
      state = state.copyWith(status: ScanFlowStatus.success);
    } on AppFailure catch (e) {
      state = state.copyWith(status: ScanFlowStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(status: ScanFlowStatus.error, errorMessage: AppFailure.generic().message);
    }
  }

  void reset() => state = const ScanFlowState();
}

final scanFlowProvider = StateNotifierProvider<ScanFlowNotifier, ScanFlowState>(
  (ref) => ScanFlowNotifier(ref),
);
