import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_ai/models/cooking_step.dart';
import 'package:fridge_ai/models/recipe.dart';
import 'package:fridge_ai/services/recipe_image_resolver.dart';

void main() {
  group('RecipeImageResolver.networkUrlForQuery', () {
    test('builds an Unsplash Source URL from a plain phrase', () {
      final url = RecipeImageResolver.networkUrlForQuery('creamy chicken rice bowl');
      expect(url, startsWith('https://source.unsplash.com/800x600/?'));
      expect(url, contains('creamy,chicken,rice,bowl'));
    });

    test('returns an empty string for a blank query', () {
      expect(RecipeImageResolver.networkUrlForQuery('   '), isEmpty);
      expect(RecipeImageResolver.networkUrlForQuery(''), isEmpty);
    });

    test('caps at 4 search terms', () {
      final url = RecipeImageResolver.networkUrlForQuery('one two three four five six');
      final query = Uri.parse(url).query;
      final terms = query.split('&').first.split(',');
      expect(terms, hasLength(4));
    });

    test('includes a stable sig parameter when a seed is given', () {
      final a = RecipeImageResolver.networkUrlForQuery('pasta', seed: 'recipe-123');
      final b = RecipeImageResolver.networkUrlForQuery('pasta', seed: 'recipe-123');
      expect(a, equals(b));
      expect(a, contains('sig='));
    });
  });

  group('RecipeImageResolver.networkUrlForRecipe', () {
    test('uses the AI-provided imageQuery when present', () {
      final recipe = Recipe(
        title: 'Chicken Rice',
        description: '',
        difficulty: Difficulty.easy,
        cookingTimeMinutes: 20,
        servings: 2,
        ingredients: const [],
        steps: const [CookingStep(order: 1, instruction: 'Cook.')],
        imageQuery: 'golden roasted chicken plate',
      );
      final url = RecipeImageResolver.networkUrlForRecipe(recipe);
      expect(url, contains('golden,roasted,chicken,plate'));
    });

    test('falls back to the recipe title when imageQuery is empty', () {
      final recipe = Recipe(
        title: 'Veggie Stir Fry',
        description: '',
        difficulty: Difficulty.easy,
        cookingTimeMinutes: 20,
        servings: 2,
        ingredients: const [],
        steps: const [],
        imageQuery: '',
      );
      final url = RecipeImageResolver.networkUrlForRecipe(recipe);
      expect(url, contains('veggie,stir,fry'));
    });
  });

  group('Recipe.fromAiJson imageQuery handling', () {
    test('uses the AI-provided imageQuery when present', () {
      final recipe = Recipe.fromAiJson({
        'title': 'Creamy Chicken Rice',
        'imageQuery': 'creamy chicken rice bowl',
      });
      expect(recipe.imageQuery, 'creamy chicken rice bowl');
    });

    test('falls back to the title when imageQuery is missing or blank', () {
      final missing = Recipe.fromAiJson({'title': 'Veggie Stir Fry'});
      expect(missing.imageQuery, 'Veggie Stir Fry');

      final blank = Recipe.fromAiJson({'title': 'Veggie Stir Fry', 'imageQuery': '   '});
      expect(blank.imageQuery, 'Veggie Stir Fry');
    });
  });
}
