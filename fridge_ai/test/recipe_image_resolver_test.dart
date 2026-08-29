import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_ai/models/cooking_step.dart';
import 'package:fridge_ai/models/ingredient.dart';
import 'package:fridge_ai/models/recipe.dart';
import 'package:fridge_ai/services/recipe_image_resolver.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  // These tests exercise RecipeImageResolver's HTTP-calling behavior with a
  // mocked client and an explicit fake accessKey (rather than relying on
  // UnsplashConfig.accessKey, which is fixed at compile time via
  // String.fromEnvironment and isn't set when running `flutter test`
  // without --dart-define). What's verified is the contract that matters
  // for the rest of the app: a successful search returns the first
  // result's photo URL, and every failure mode (network error, non-200,
  // empty results, malformed JSON) resolves to an empty string rather than
  // throwing — exactly what FallbackImage needs to safely fall back to a
  // local placeholder.
  group('RecipeImageResolver.urlForQuery', () {
    test('returns an empty string for a blank query without making a request', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return http.Response('', 200);
      });

      expect(await RecipeImageResolver.urlForQuery('   ', client: client, accessKey: 'test-key'), isEmpty);
      expect(await RecipeImageResolver.urlForQuery('', client: client, accessKey: 'test-key'), isEmpty);
      expect(callCount, 0);
    });

    test('returns the first result\'s regular photo URL on a successful search', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), contains('api.unsplash.com/search/photos'));
        expect(request.url.queryParameters['query'], 'unique query one');
        return http.Response(
          jsonEncode({
            'results': [
              {
                'urls': {
                  'regular': 'https://images.unsplash.com/photo-regular.jpg',
                  'small': 'https://images.unsplash.com/photo-small.jpg',
                },
              },
            ],
          }),
          200,
        );
      });

      final url = await RecipeImageResolver.urlForQuery('unique query one', client: client, accessKey: 'test-key');
      expect(url, 'https://images.unsplash.com/photo-regular.jpg');
    });

    test('falls back to the small photo URL if regular is missing', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'urls': {'small': 'https://images.unsplash.com/photo-small-2.jpg'},
              },
            ],
          }),
          200,
        );
      });

      final url = await RecipeImageResolver.urlForQuery('unique query two', client: client, accessKey: 'test-key');
      expect(url, 'https://images.unsplash.com/photo-small-2.jpg');
    });

    test('returns an empty string when the search has no results', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final url = await RecipeImageResolver.urlForQuery('unique query three', client: client, accessKey: 'test-key');
      expect(url, isEmpty);
    });

    test('returns an empty string on a non-200 response', () async {
      final client = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final url = await RecipeImageResolver.urlForQuery('unique query four', client: client, accessKey: 'test-key');
      expect(url, isEmpty);
    });

    test('returns an empty string on malformed JSON instead of throwing', () async {
      final client = MockClient((request) async {
        return http.Response('not json', 200);
      });

      final url = await RecipeImageResolver.urlForQuery('unique query five', client: client, accessKey: 'test-key');
      expect(url, isEmpty);
    });

    test('returns an empty string when the request throws instead of propagating', () async {
      final client = MockClient((request) async {
        throw Exception('network unreachable');
      });

      final url = await RecipeImageResolver.urlForQuery('unique query six', client: client, accessKey: 'test-key');
      expect(url, isEmpty);
    });

    test('caches a resolved URL so a repeat query does not hit the network again', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return http.Response(
          jsonEncode({
            'results': [
              {
                'urls': {'regular': 'https://images.unsplash.com/cached.jpg'},
              },
            ],
          }),
          200,
        );
      });

      final a = await RecipeImageResolver.urlForQuery('unique cache query', client: client, accessKey: 'test-key');
      final b = await RecipeImageResolver.urlForQuery('unique cache query', client: client, accessKey: 'test-key');
      expect(a, b);
      expect(callCount, 1);
    });
  });

  group('RecipeImageResolver.urlForRecipe', () {
    test('searches using the AI-provided imageQuery when present', () async {
      final recipe = Recipe(
        title: 'Chicken Rice',
        description: '',
        difficulty: Difficulty.easy,
        cookingTimeMinutes: 20,
        servings: 2,
        ingredients: const [],
        steps: const [CookingStep(order: 1, instruction: 'Cook.')],
        imageQuery: 'golden roasted chicken plate unique',
      );

      final client = MockClient((request) async {
        expect(request.url.queryParameters['query'], 'golden roasted chicken plate unique');
        return http.Response(
          jsonEncode({
            'results': [
              {
                'urls': {'regular': 'https://images.unsplash.com/chicken.jpg'},
              },
            ],
          }),
          200,
        );
      });

      final url = await RecipeImageResolver.urlForRecipe(recipe, client: client, accessKey: 'test-key');
      expect(url, 'https://images.unsplash.com/chicken.jpg');
    });

    test('falls back to the recipe title when imageQuery is empty', () async {
      final recipe = Recipe(
        title: 'Veggie Stir Fry Unique',
        description: '',
        difficulty: Difficulty.easy,
        cookingTimeMinutes: 20,
        servings: 2,
        ingredients: const [],
        steps: const [],
        imageQuery: '',
      );

      final client = MockClient((request) async {
        expect(request.url.queryParameters['query'], 'Veggie Stir Fry Unique');
        return http.Response(
          jsonEncode({
            'results': [
              {
                'urls': {'regular': 'https://images.unsplash.com/stirfry.jpg'},
              },
            ],
          }),
          200,
        );
      });

      final url = await RecipeImageResolver.urlForRecipe(recipe, client: client, accessKey: 'test-key');
      expect(url, 'https://images.unsplash.com/stirfry.jpg');
    });
  });

  group('RecipeImageResolver.urlForIngredient', () {
    test('searches using the ingredient\'s own name, not its category', () async {
      final ingredient = Ingredient(
        name: 'Red Bell Pepper Unique',
        quantity: '2',
        category: IngredientCategory.vegetables,
      );

      final client = MockClient((request) async {
        expect(request.url.queryParameters['query'], 'Red Bell Pepper Unique');
        return http.Response(
          jsonEncode({
            'results': [
              {
                'urls': {'regular': 'https://images.unsplash.com/bellpepper.jpg'},
              },
            ],
          }),
          200,
        );
      });

      final url = await RecipeImageResolver.urlForIngredient(ingredient, client: client, accessKey: 'test-key');
      expect(url, 'https://images.unsplash.com/bellpepper.jpg');
    });

    test('prefers imageQuery over name when both are present', () async {
      final ingredient = Ingredient(
        name: 'Chicken',
        quantity: '500g',
        category: IngredientCategory.meat,
        imageQuery: 'raw chicken breast fillet unique',
      );

      final client = MockClient((request) async {
        expect(request.url.queryParameters['query'], 'raw chicken breast fillet unique');
        return http.Response(
          jsonEncode({
            'results': [
              {
                'urls': {'regular': 'https://images.unsplash.com/chicken-breast.jpg'},
              },
            ],
          }),
          200,
        );
      });

      final url = await RecipeImageResolver.urlForIngredient(ingredient, client: client, accessKey: 'test-key');
      expect(url, 'https://images.unsplash.com/chicken-breast.jpg');
    });

    test('returns an empty string when nothing usable comes back', () async {
      final ingredient = Ingredient(
        name: 'Unique Mystery Item',
        quantity: '1',
        category: IngredientCategory.pantry,
      );

      final client = MockClient((request) async {
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final url = await RecipeImageResolver.urlForIngredient(ingredient, client: client, accessKey: 'test-key');
      expect(url, isEmpty);
    });
  });

  group('Recipe.fromAiJson imageQuery handling', () {
    test('uses the AI-provided imageQuery when present', () {
      final recipe = Recipe.fromAiJson(const {
        'title': 'Creamy Chicken Rice',
        'imageQuery': 'creamy chicken rice bowl',
      });
      expect(recipe.imageQuery, 'creamy chicken rice bowl');
    });

    test('falls back to the title when imageQuery is missing or blank', () {
      final missing = Recipe.fromAiJson(const {'title': 'Veggie Stir Fry'});
      expect(missing.imageQuery, 'Veggie Stir Fry');

      final blank = Recipe.fromAiJson(const {'title': 'Veggie Stir Fry', 'imageQuery': '   '});
      expect(blank.imageQuery, 'Veggie Stir Fry');
    });
  });
}
