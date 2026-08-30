import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_ai/models/ingredient.dart';

void main() {
  group('IngredientCategory.fromString', () {
    test('parses exact enum names', () {
      expect(IngredientCategory.fromString('vegetables'), IngredientCategory.vegetables);
      expect(IngredientCategory.fromString('dairy'), IngredientCategory.dairy);
    });

    test('parses display labels case-insensitively', () {
      expect(IngredientCategory.fromString('Meat'), IngredientCategory.meat);
      expect(IngredientCategory.fromString('FRUITS'), IngredientCategory.fruits);
    });

    test('falls back to heuristic keyword matching for AI phrasing variants', () {
      expect(IngredientCategory.fromString('poultry'), IngredientCategory.meat);
      expect(IngredientCategory.fromString('fresh vegetable'), IngredientCategory.vegetables);
      expect(IngredientCategory.fromString('cheese product'), IngredientCategory.dairy);
      expect(IngredientCategory.fromString('whole grain bread'), IngredientCategory.grains);
    });

    test('defaults to pantry for null or unrecognized values', () {
      expect(IngredientCategory.fromString(null), IngredientCategory.pantry);
      expect(IngredientCategory.fromString('spaceship parts'), IngredientCategory.pantry);
    });
  });

  group('Ingredient.fromAiJson', () {
    test('parses a well-formed AI response', () {
      final ingredient = Ingredient.fromAiJson(const {
        'name': 'Eggs',
        'quantity': '6',
        'category': 'dairy',
      });

      expect(ingredient.name, 'Eggs');
      expect(ingredient.quantity, '6');
      expect(ingredient.category, IngredientCategory.dairy);
    });

    test('coerces a numeric quantity into a string', () {
      final ingredient = Ingredient.fromAiJson(const {'name': 'Tomatoes', 'quantity': 3});
      expect(ingredient.quantity, '3');
    });

    test('falls back to defaults when fields are missing or malformed', () {
      final ingredient = Ingredient.fromAiJson(const <String, dynamic>{});
      expect(ingredient.name, 'Unknown item');
      expect(ingredient.quantity, '1');
      expect(ingredient.category, IngredientCategory.pantry);
    });

    test('falls back when name is blank or the wrong type', () {
      final blank = Ingredient.fromAiJson(const {'name': '   ', 'quantity': '2'});
      expect(blank.name, 'Unknown item');

      final wrongType = Ingredient.fromAiJson(const {'name': 42, 'quantity': '2'});
      expect(wrongType.name, 'Unknown item');
    });

    test('never throws on a completely empty or null-heavy payload', () {
      expect(() => Ingredient.fromAiJson(const {'name': null, 'quantity': null, 'category': null}),
          returnsNormally);
    });
  });

  group('Ingredient JSON round-trip', () {
    test('toJson -> fromJson preserves all fields', () {
      final original = Ingredient(
        name: 'Milk',
        quantity: '1 bottle',
        category: IngredientCategory.dairy,
        expirationDate: DateTime(2026, 9, 1),
      );

      final restored = Ingredient.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.quantity, original.quantity);
      expect(restored.category, original.category);
      expect(restored.expirationDate, original.expirationDate);
    });

    test('fromJson tolerates a missing expirationDate', () {
      final ingredient = Ingredient.fromJson(const {
        'id': 'abc123',
        'name': 'Rice',
        'quantity': '1 kg',
        'category': 'grains',
      });

      expect(ingredient.expirationDate, isNull);
      expect(ingredient.name, 'Rice');
    });
  });

  group('Ingredient.copyWith', () {
    test('updates only the requested fields', () {
      final original = Ingredient(name: 'Butter', quantity: '200g', category: IngredientCategory.dairy);
      final updated = original.copyWith(quantity: '250g');

      expect(updated.id, original.id);
      expect(updated.name, original.name);
      expect(updated.quantity, '250g');
    });

    test('clearExpirationDate removes an existing expiration date', () {
      final original = Ingredient(
        name: 'Yogurt',
        quantity: '2',
        expirationDate: DateTime(2026, 10, 1),
      );
      final updated = original.copyWith(clearExpirationDate: true);

      expect(updated.expirationDate, isNull);
    });
  });

  group('Ingredient.isSameItemAs', () {
    test('matches identical names', () {
      final a = Ingredient(name: 'Tomato', quantity: '1');
      final b = Ingredient(name: 'Tomato', quantity: '1');
      expect(a.isSameItemAs(b), isTrue);
    });

    test('matches case-insensitively', () {
      final a = Ingredient(name: 'tomato', quantity: '1');
      final b = Ingredient(name: 'TOMATO', quantity: '1');
      expect(a.isSameItemAs(b), isTrue);
    });

    test('matches simple plurals', () {
      final a = Ingredient(name: 'Tomato', quantity: '1');
      final b = Ingredient(name: 'Tomatoes', quantity: '1');
      expect(a.isSameItemAs(b), isTrue);
    });

    test('does not match different items', () {
      final a = Ingredient(name: 'Tomato', quantity: '1');
      final b = Ingredient(name: 'Potato', quantity: '1');
      expect(a.isSameItemAs(b), isFalse);
    });
  });

  group('Ingredient.mergedWith', () {
    test('adds two plain numeric quantities', () {
      final a = Ingredient(name: 'Tomato', quantity: '1');
      final b = Ingredient(name: 'Tomato', quantity: '1');
      expect(a.mergedWith(b).quantity, '2');
    });

    test('adds numeric quantities sharing a unit', () {
      final a = Ingredient(name: 'Flour', quantity: '200 g');
      final b = Ingredient(name: 'Flour', quantity: '100 g');
      expect(a.mergedWith(b).quantity, '300 g');
    });

    test('keeps the merged entry\'s id/category/expiration from the original', () {
      final original = Ingredient(
        name: 'Tomato',
        quantity: '1',
        category: IngredientCategory.vegetables,
        expirationDate: DateTime(2026, 9, 5),
      );
      final incoming = Ingredient(name: 'Tomato', quantity: '1');
      final merged = original.mergedWith(incoming);

      expect(merged.id, original.id);
      expect(merged.category, IngredientCategory.vegetables);
      expect(merged.expirationDate, DateTime(2026, 9, 5));
      expect(merged.quantity, '2');
    });

    test('falls back to a combined label when units differ', () {
      final a = Ingredient(name: 'Milk', quantity: '1 bottle');
      final b = Ingredient(name: 'Milk', quantity: '500 ml');
      expect(a.mergedWith(b).quantity, '1 bottle + 500 ml');
    });

    test('falls back to a combined label for non-numeric quantities', () {
      final a = Ingredient(name: 'Basil', quantity: 'a bunch');
      final b = Ingredient(name: 'Basil', quantity: 'a bunch');
      expect(a.mergedWith(b).quantity, 'a bunch');
    });
  });
}
