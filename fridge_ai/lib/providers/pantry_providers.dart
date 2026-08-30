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

  /// Adds [ingredient] to the pantry — or, if an item with the same name
  /// (e.g. "Tomato" scanned a second time) is already in the pantry, merges
  /// into that existing card (combining quantities) instead of creating a
  /// second, duplicate card for the same item.
  Future<void> addIngredient(Ingredient ingredient) async {
    final existingIndex = state.indexWhere((i) => i.isSameItemAs(ingredient));
    final existing = existingIndex == -1 ? null : state[existingIndex];
    if (existing != null) {
      final merged = existing.mergedWith(ingredient);
      await _ref.read(pantryRepositoryProvider).update(merged);
      state = [for (final i in state) if (i.id == existing.id) merged else i];
      return;
    }
    await _ref.read(pantryRepositoryProvider).add(ingredient);
    state = [ingredient, ...state];
  }

  /// Batch version of [addIngredient] (used when confirming a scan) — each
  /// incoming ingredient is merged into a matching existing pantry entry by
  /// name, and duplicates *within* the same batch are merged together too,
  /// so scanning two tomatoes in one photo also produces a single "Tomato"
  /// card with quantity 2 rather than two separate cards.
  Future<void> addIngredients(List<Ingredient> ingredients) async {
    if (ingredients.isEmpty) return;

    // First, merge duplicates within the incoming batch itself.
    final mergedBatch = <Ingredient>[];
    for (final incoming in ingredients) {
      final matchIndex = mergedBatch.indexWhere((i) => i.isSameItemAs(incoming));
      if (matchIndex == -1) {
        mergedBatch.add(incoming);
      } else {
        mergedBatch[matchIndex] = mergedBatch[matchIndex].mergedWith(incoming);
      }
    }

    // Then merge each batch item into any existing pantry entry, or add it
    // as new if there's no match yet.
    var nextState = state;
    final toAdd = <Ingredient>[];
    final toUpdate = <Ingredient>[];
    for (final incoming in mergedBatch) {
      final existingIndex = nextState.indexWhere((i) => i.isSameItemAs(incoming));
      if (existingIndex == -1) {
        toAdd.add(incoming);
        nextState = [incoming, ...nextState];
      } else {
        final merged = nextState[existingIndex].mergedWith(incoming);
        toUpdate.add(merged);
        nextState = [for (final i in nextState) if (i.id == merged.id) merged else i];
      }
    }

    if (toAdd.isNotEmpty) await _ref.read(pantryRepositoryProvider).addAll(toAdd);
    for (final ingredient in toUpdate) {
      await _ref.read(pantryRepositoryProvider).update(ingredient);
    }
    state = nextState;
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

  /// Replaces the draft with a freshly-scanned batch, merging any items
  /// within that batch that are the same ingredient (e.g. two tomatoes
  /// detected in one photo) into a single entry with a combined quantity.
  void setAll(List<Ingredient> ingredients) {
    final merged = <Ingredient>[];
    for (final incoming in ingredients) {
      final matchIndex = merged.indexWhere((i) => i.isSameItemAs(incoming));
      if (matchIndex == -1) {
        merged.add(incoming);
      } else {
        merged[matchIndex] = merged[matchIndex].mergedWith(incoming);
      }
    }
    state = merged;
  }

  /// Adds a manually-entered ingredient to the draft, merging into an
  /// existing draft entry of the same item (rather than creating a
  /// duplicate card) if one is already present.
  void add(Ingredient ingredient) {
    final matchIndex = state.indexWhere((i) => i.isSameItemAs(ingredient));
    if (matchIndex == -1) {
      state = [...state, ingredient];
    } else {
      state = [
        for (var i = 0; i < state.length; i++) if (i == matchIndex) state[i].mergedWith(ingredient) else state[i],
      ];
    }
  }

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
