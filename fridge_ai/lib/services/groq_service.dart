import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../core/constants/groq_config.dart';
import '../core/utils/app_failure.dart';
import '../core/utils/network_utils.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/scan_result.dart';
import 'recipe_image_resolver.dart';

/// Talks directly to the Groq API (https://api.groq.com) — there is no
/// custom backend. Two responsibilities live here:
///
///  1. Vision: analyze a food/fridge/grocery photo and return a structured
///     list of detected ingredients.
///  2. Text: given a confirmed ingredient list (+ optional preferences),
///     generate a set of structured recipes.
///
/// Every public method returns either a parsed model or throws an
/// [AppFailure] — callers never see a raw [Exception], [SocketException],
/// [FormatException], etc.
class GroqService {
  GroqService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // ---------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------

  /// Sends a food photo to Groq's vision model and returns the detected
  /// ingredients. Never throws for "AI couldn't identify anything" — that
  /// case is represented as `ScanResult.success == false`. It only throws
  /// [AppFailure] for infrastructure-level problems (no internet, API
  /// error, rate limit, timeout, missing key).
  Future<ScanResult> analyzeFoodImage(File imageFile) async {
    _ensureConfigured();
    await _ensureOnline();

    final bytes = await imageFile.readAsBytes();
    final compressed = await _compressForUpload(bytes);
    final base64Image = base64Encode(compressed);
    // The photo is always re-encoded as JPEG by _compressForUpload below,
    // regardless of the original file extension/format.
    const mimeType = 'image/jpeg';

    final body = {
      'model': GroqConfig.visionModel,
      'max_tokens': GroqConfig.maxTokensVision,
      'temperature': 0.2,
      'response_format': {'type': 'json_object'},
      // qwen3.6-27b is a "thinking" model by default (reasoning_effort
      // defaults to "default", i.e. thinking mode ON). Left alone, it
      // prepends a <think>...</think> block to its output before the JSON,
      // which _tryDecodeJsonObject would otherwise have to fish the JSON
      // out of. "none" fully disables reasoning for the qwen3 family (per
      // Groq's docs), and reasoning_format "hidden" is a second safety net
      // in case a future model swap here still reasons — either way we
      // want only the final JSON in `content`.
      'reasoning_effort': 'none',
      'reasoning_format': 'hidden',
      'messages': [
        {
          'role': 'system',
          'content': _visionSystemPrompt,
        },
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _visionUserPrompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
            },
          ],
        },
      ],
    };

    final response = await _post(body);
    final content = _extractMessageContent(response);
    final json = _tryDecodeJsonObject(content);

    if (json == null) {
      return ScanResult.empty(AppFailure.invalidResponse().message);
    }

    return ScanResult.fromAiJson(json);
  }

  /// Generates recipes from a confirmed ingredient list. Optionally takes
  /// free-form preference hints (dietary restrictions, allergies, favorite
  /// cuisines, desired serving size) which are folded into the prompt.
  ///
  /// Always returns a (possibly empty) list — never throws for "AI
  /// returned nothing useful"; the UI shows an empty state instead. Throws
  /// [AppFailure] only for infrastructure-level failures.
  Future<List<Recipe>> generateRecipes({
    required List<Ingredient> ingredients,
    List<String> dietaryPreferences = const [],
    List<String> allergies = const [],
    List<String> favoriteCuisines = const [],
    int servings = 2,
  }) async {
    _ensureConfigured();
    await _ensureOnline();

    if (ingredients.isEmpty) {
      return const [];
    }

    final ingredientLines = ingredients
        .map((i) => '- ${i.name} (${i.quantity})')
        .join('\n');

    final preferenceLines = StringBuffer();
    if (dietaryPreferences.isNotEmpty) {
      preferenceLines.writeln('Dietary preferences: ${dietaryPreferences.join(', ')}.');
    }
    if (allergies.isNotEmpty) {
      preferenceLines.writeln('Allergies to strictly avoid: ${allergies.join(', ')}.');
    }
    if (favoriteCuisines.isNotEmpty) {
      preferenceLines.writeln('Favorite cuisines: ${favoriteCuisines.join(', ')}.');
    }
    preferenceLines.writeln('Preferred serving size: $servings.');

    final userPrompt =
        '$_recipeUserPromptIntro\n\nAvailable ingredients:\n$ingredientLines\n\n${preferenceLines.toString()}\n$_recipeUserPromptOutro';

    final body = {
      'model': GroqConfig.textModel,
      'max_tokens': GroqConfig.maxTokensRecipes,
      'temperature': 0.6,
      'response_format': {'type': 'json_object'},
      // openai/gpt-oss-120b always reasons internally (its reasoning can't
      // be disabled, only tuned via reasoning_effort low/medium/high) and
      // by default surfaces that reasoning as part of the response.
      // "hidden" keeps `content` limited to the final answer so it stays
      // pure JSON for _tryDecodeJsonObject.
      'reasoning_effort': 'low',
      'reasoning_format': 'hidden',
      'messages': [
        {'role': 'system', 'content': _recipeSystemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
    };

    final response = await _post(body);
    final content = _extractMessageContent(response);
    final json = _tryDecodeJsonObject(content);

    if (json == null) {
      throw AppFailure.invalidResponse();
    }

    final rawRecipes = json['recipes'];
    if (rawRecipes is! List) {
      return const [];
    }

    final availableNames = ingredients.map((i) => i.name.toLowerCase().trim()).toSet();

    final recipes = <Recipe>[];
    for (final item in rawRecipes) {
      try {
        Map<String, dynamic>? recipeJson;
        if (item is Map<String, dynamic>) {
          recipeJson = item;
        } else if (item is Map) {
          recipeJson = Map<String, dynamic>.from(item);
        }
        if (recipeJson == null) continue;

        final recipe = Recipe.fromAiJson(recipeJson);
        recipes.add(_reconcileAvailability(recipe, availableNames));
      } catch (_) {
        // A single malformed recipe must never take down the whole batch.
        continue;
      }
    }

    return recipes;
  }

  void dispose() => _client.close();

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  /// The AI sometimes mismarks `available` — recompute it against the
  /// actual pantry so the "already have / need to buy" split in the UI is
  /// always trustworthy, regardless of what the model claimed.
  ///
  /// Also resolves a real-photo [Recipe.imageUrl] here (via
  /// [RecipeImageResolver], no image API key required) so every recipe that
  /// comes back from Groq already carries a genuine food photo instead of
  /// only a local placeholder. `FallbackImage` still falls back to the
  /// bundled placeholder automatically if this URL ever fails to load.
  Recipe _reconcileAvailability(Recipe recipe, Set<String> availableNames) {
    final reconciled = recipe.ingredients.map((ri) {
      final isAvailable = availableNames.any(
        (owned) => owned.contains(ri.name.toLowerCase().trim()) ||
            ri.name.toLowerCase().trim().contains(owned),
      );
      return isAvailable == ri.available
          ? ri
          : (isAvailable ? ri.copyWithAvailable(true) : ri.copyWithAvailable(false));
    }).toList();

    return Recipe(
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      difficulty: recipe.difficulty,
      cookingTimeMinutes: recipe.cookingTimeMinutes,
      servings: recipe.servings,
      ingredients: reconciled,
      steps: recipe.steps,
      tags: recipe.tags,
      imageQuery: recipe.imageQuery,
      imageUrl: RecipeImageResolver.networkUrlForRecipe(recipe),
      createdAt: recipe.createdAt,
    );
  }

  void _ensureConfigured() {
    if (!GroqConfig.hasApiKey) {
      throw AppFailure.missingApiKey();
    }
  }

  Future<void> _ensureOnline() async {
    final online = await NetworkUtils.hasConnection();
    if (!online) {
      throw AppFailure.noInternet();
    }
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(GroqConfig.chatCompletionsEndpoint),
            headers: GroqConfig.headers,
            body: jsonEncode(body),
          )
          .timeout(GroqConfig.requestTimeout);
    } on SocketException {
      throw AppFailure.noInternet();
    } on HttpException {
      throw AppFailure.apiError();
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw AppFailure.timeout();
      }
      throw AppFailure.apiError();
    }

    if (response.statusCode == 429) {
      throw AppFailure.rateLimit();
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AppFailure.missingApiKey();
    }
    if (response.statusCode >= 500) {
      throw AppFailure.apiError();
    }
    if (response.statusCode != 200) {
      throw AppFailure.apiError();
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw AppFailure.invalidResponse();
    } catch (_) {
      throw AppFailure.invalidResponse();
    }
  }

  String _extractMessageContent(Map<String, dynamic> response) {
    try {
      final choices = response['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map) {
          final message = first['message'];
          if (message is Map) {
            final content = message['content'];
            if (content is String) return content;
          }
        }
      }
    } catch (_) {
      // fall through
    }
    throw AppFailure.invalidResponse();
  }

  /// The model is asked for JSON but may still wrap it in prose or code
  /// fences. This defensively extracts the first top-level JSON object.
  Map<String, dynamic>? _tryDecodeJsonObject(String raw) {
    var text = raw.trim();

    // Defense in depth: if a reasoning model's <think>...</think> block
    // ever leaks into `content` (e.g. a future Groq default change),
    // strip it before parsing rather than letting it break JSON decoding.
    text = text.replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '').trim();

    // Strip Markdown code fences if present (```json ... ``` or ``` ... ```)
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
      text = text.trim();
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Fall back to locating the outermost { ... } span.
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        try {
          final decoded = jsonDecode(text.substring(start, end + 1));
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  /// Downscales and re-encodes a photo before it's base64-embedded and sent
  /// to the vision API.
  ///
  /// Photos taken via the in-app camera (scanner_screen.dart uses
  /// `ResolutionPreset.high` with no compression) can be several megabytes
  /// at full resolution. Groq's vision endpoint enforces a 20MB request
  /// size limit on base64-embedded images (qwen/qwen3.6-27b, see
  /// https://console.groq.com/docs/vision), and very large/high-resolution
  /// photos were intermittently rejected or failed to yield any detected
  /// ingredients — surfacing to the user as "I couldn't spot any food in
  /// that photo" even for a perfectly clear picture, often requiring
  /// several retries. Resizing to a reasonable max dimension and
  /// re-encoding as JPEG keeps every upload comfortably within limits
  /// while remaining more than sharp enough for food/ingredient
  /// recognition, and also makes uploads noticeably faster on mobile data.
  Future<Uint8List> _compressForUpload(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        // Not a format the `image` package can parse (shouldn't normally
        // happen for camera/gallery output) — fall back to the original
        // bytes rather than failing the whole scan.
        return bytes;
      }

      const maxDimension = 1568;
      final needsResize = decoded.width > maxDimension || decoded.height > maxDimension;
      final resized = needsResize
          ? img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? maxDimension : null,
              height: decoded.height > decoded.width ? maxDimension : null,
              interpolation: img.Interpolation.average,
            )
          : decoded;

      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (_) {
      // Compression is a best-effort optimization — never let it block a
      // scan. Worst case, the original (larger) photo is uploaded instead.
      return bytes;
    }
  }

  static const String _visionSystemPrompt = '''
You are FridgeAI's vision assistant. You identify edible food items, groceries and ingredients from a photo of a fridge, pantry, grocery haul, or table of food.

Always respond with a single JSON object only — no prose, no markdown fences. The JSON shape must be exactly:

{
  "ingredients": [
    { "name": "string", "quantity": "string, e.g. '6' or '500 g' or '1 bottle'", "category": "one of vegetables, meat, dairy, fruits, grains, pantry" }
  ],
  "note": "optional short string, e.g. if the photo was unclear"
}

Rules:
- Only include items you can actually see with reasonable confidence.
- Use realistic, commonly-understood ingredient names (e.g. "Eggs", "Tomatoes", "Chicken breast", "Milk").
- Estimate quantity as best you can from visual count or packaging; use simple units (g, kg, ml, l, or a plain count).
- If you cannot identify any food at all, return {"ingredients": [], "note": "short reason"}.
- Never include non-food items.
- Never include commentary outside the JSON object.
''';

  static const String _visionUserPrompt =
      'Identify every distinct food item / ingredient visible in this photo. Return only the JSON object described in your instructions.';

  static const String _recipeSystemPrompt = '''
You are FridgeAI's recipe generation assistant. Given a list of ingredients the user already has (and optional preferences), you generate practical, appealing recipes that primarily use those ingredients.

Always respond with a single JSON object only — no prose, no markdown fences. The JSON shape must be exactly:

{
  "recipes": [
    {
      "title": "string",
      "description": "one or two friendly sentences",
      "difficulty": "easy | medium | hard",
      "cookingTimeMinutes": number,
      "servings": number,
      "ingredients": [
        { "name": "string", "quantity": "string", "available": true or false }
      ],
      "instructions": [
        { "order": number, "instruction": "string", "timerSeconds": number or null }
      ],
      "tags": ["subset of: quick, easy, medium, highProtein, vegetarian, breakfast, lunch, dinner, dessert"],
      "imageQuery": "2-4 word plain-English food-photo search phrase for this dish, e.g. 'creamy chicken rice bowl'"
    }
  ]
}

Rules:
- Generate between 3 and 6 recipes.
- Mark an ingredient "available": true only if it closely matches something in the provided ingredient list; otherwise false (it must be bought).
- Prefer recipes that use as many of the provided ingredients as possible.
- Respect allergies strictly — never include an allergen ingredient.
- Keep instructions concise, numbered, and realistic for a home cook.
- Include a timerSeconds value on any step that involves waiting (baking, simmering, resting, marinating, boiling); omit/null otherwise.
- imageQuery should describe how the finished dish looks/is plated, not the raw ingredients (good: "grilled salmon asparagus plate"; avoid: "salmon, asparagus, lemon").
- Never include commentary outside the JSON object.
''';

  static const String _recipeUserPromptIntro =
      'Generate recipes primarily using the ingredients I already have.';

  static const String _recipeUserPromptOutro =
      'Return only the JSON object described in your instructions.';
}
