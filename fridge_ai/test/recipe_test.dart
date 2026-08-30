import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_ai/models/recipe.dart';
import 'package:fridge_ai/models/recipe_ingredient.dart';
import 'package:fridge_ai/models/cooking_step.dart';

void main() {
  group('Difficulty.fromString', () {
    test('parses known values case-insensitively', () {
      expect(Difficulty.fromString('easy'), Difficulty.easy);
      expect(Difficulty.fromString('HARD'), Difficulty.hard);
      expect(Difficulty.fromString('Medium'), Difficulty.medium);
    });

    test('defaults to medium for null or unrecognized values', () {
      expect(Difficulty.fromString(null), Difficulty.medium);
      expect(Difficulty.fromString('impossible'), Difficulty.medium);
    });
  });

  group('RecipeTag.fromString', () {
    test('parses enum names and human labels', () {
      expect(RecipeTag.fromString('highProtein'), RecipeTag.highProtein);
      expect(RecipeTag.fromString('High Protein'), RecipeTag.highProtein);
      expect(RecipeTag.fromString('vegetarian'), RecipeTag.vegetarian);
    });

    test('returns null for unrecognized or missing values', () {
      expect(RecipeTag.fromString('spicy'), isNull);
      expect(RecipeTag.fromString(null), isNull);
    });
  });

  group('RecipeIngredient.fromAiJson', () {
    test('parses a well-formed entry', () {
      final ingredient = RecipeIngredient.fromAiJson(const {
        'name': 'Chicken breast',
        'quantity': '500g',
        'available': true,
      });
      expect(ingredient.name, 'Chicken breast');
      expect(ingredient.quantity, '500g');
      expect(ingredient.available, isTrue);
    });

    test('coerces a numeric quantity and string "true"/"false"', () {
      final a = RecipeIngredient.fromAiJson(const {'name': 'Eggs', 'quantity': 6, 'available': 'true'});
      expect(a.quantity, '6');
      expect(a.available, isTrue);

      final b = RecipeIngredient.fromAiJson(const {'name': 'Cream', 'available': 'false'});
      expect(b.available, isFalse);
    });

    test('falls back to safe defaults on malformed input', () {
      final ingredient = RecipeIngredient.fromAiJson(const <String, dynamic>{});
      expect(ingredient.name, 'Ingredient');
      expect(ingredient.quantity, '');
      expect(ingredient.available, isFalse);
    });
  });

  group('CookingStep.fromAiJson', () {
    test('parses instruction, order and timer', () {
      final step = CookingStep.fromAiJson(const {
        'order': 2,
        'instruction': 'Simmer for 10 minutes.',
        'timerSeconds': 600,
      }, 1);
      expect(step.order, 2);
      expect(step.instruction, 'Simmer for 10 minutes.');
      expect(step.timerSeconds, 600);
    });

    test('uses fallbackOrder and a safe instruction when missing', () {
      final step = CookingStep.fromAiJson(const <String, dynamic>{}, 5);
      expect(step.order, 5);
      expect(step.instruction, isNotEmpty);
      expect(step.timerSeconds, isNull);
    });

    test('ignores a non-positive or malformed timer', () {
      final step = CookingStep.fromAiJson(const {'instruction': 'Mix.', 'timerSeconds': -10}, 1);
      expect(step.timerSeconds, isNull);
    });
  });

  group('Recipe.fromAiJson', () {
    test('parses a complete, well-formed AI recipe response', () {
      final recipe = Recipe.fromAiJson(const {
        'title': 'Creamy Chicken Rice',
        'description': 'A comforting one-pot dinner.',
        'difficulty': 'easy',
        'cookingTimeMinutes': 25,
        'servings': 4,
        'ingredients': [
          {'name': 'Chicken', 'quantity': '500g', 'available': true},
          {'name': 'Cream', 'quantity': '1 cup', 'available': false},
        ],
        'instructions': [
          {'order': 1, 'instruction': 'Sear the chicken.'},
          {'order': 2, 'instruction': 'Add rice and simmer.', 'timerSeconds': 900},
        ],
        'tags': ['dinner', 'quick'],
      });

      expect(recipe.title, 'Creamy Chicken Rice');
      expect(recipe.difficulty, Difficulty.easy);
      expect(recipe.cookingTimeMinutes, 25);
      expect(recipe.servings, 4);
      expect(recipe.ingredients, hasLength(2));
      expect(recipe.steps, hasLength(2));
      expect(recipe.tags, containsAll([RecipeTag.dinner, RecipeTag.quick]));
      expect(recipe.matchPercentage, 50);
    });

    test('accepts plain string instructions as steps', () {
      final recipe = Recipe.fromAiJson(const {
        'title': 'Simple Toast',
        'instructions': ['Toast the bread.', 'Add butter.'],
      });
      expect(recipe.steps, hasLength(2));
      expect(recipe.steps.first.instruction, 'Toast the bread.');
      expect(recipe.steps.first.order, 1);
    });

    test('falls back to safe defaults for a completely empty payload', () {
      final recipe = Recipe.fromAiJson(const <String, dynamic>{});
      expect(recipe.title, 'Untitled recipe');
      expect(recipe.difficulty, Difficulty.medium);
      expect(recipe.cookingTimeMinutes, 20);
      expect(recipe.servings, 2);
      expect(recipe.ingredients, isEmpty);
      expect(recipe.matchPercentage, 0);
    });

    test('coerces string-typed numeric fields', () {
      final recipe = Recipe.fromAiJson(const {
        'title': 'Test',
        'cookingTimeMinutes': '30 min',
        'servings': '6',
      });
      expect(recipe.cookingTimeMinutes, 30);
      expect(recipe.servings, 6);
    });

    test('never throws on deeply malformed input', () {
      expect(
        () => Recipe.fromAiJson(const {
          'title': 123,
          'ingredients': 'not a list',
          'instructions': null,
          'tags': 'not a list either',
        }),
        returnsNormally,
      );
    });
  });

  group('Recipe JSON round-trip', () {
    test('toJson -> fromJson preserves all fields', () {
      final original = Recipe(
        title: 'Veggie Stir Fry',
        description: 'Fast and fresh.',
        difficulty: Difficulty.medium,
        cookingTimeMinutes: 15,
        servings: 2,
        ingredients: const [
          RecipeIngredient(name: 'Broccoli', quantity: '1 head', available: true),
        ],
        steps: const [
          CookingStep(order: 1, instruction: 'Chop vegetables.'),
        ],
        tags: const [RecipeTag.vegetarian, RecipeTag.quick],
      );

      final restored = Recipe.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.difficulty, original.difficulty);
      expect(restored.ingredients.length, original.ingredients.length);
      expect(restored.steps.length, original.steps.length);
      expect(restored.tags, original.tags);
    });
  });

  group('Recipe.matchPercentage', () {
    test('is 100 when all ingredients are available', () {
      final recipe = Recipe(
        title: 'Test',
        description: '',
        difficulty: Difficulty.easy,
        cookingTimeMinutes: 10,
        servings: 1,
        ingredients: const [
          RecipeIngredient(name: 'A', quantity: '1', available: true),
          RecipeIngredient(name: 'B', quantity: '1', available: true),
        ],
        steps: const [],
      );
      expect(recipe.matchPercentage, 100);
      expect(recipe.missingIngredients, isEmpty);
    });

    test('is 0 for a recipe with no ingredients', () {
      final recipe = Recipe(
        title: 'Test',
        description: '',
        difficulty: Difficulty.easy,
        cookingTimeMinutes: 10,
        servings: 1,
        ingredients: const [],
        steps: const [],
      );
      expect(recipe.matchPercentage, 0);
    });
  });
}
