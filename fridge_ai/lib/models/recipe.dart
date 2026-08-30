import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'cooking_step.dart';
import 'recipe_ingredient.dart';

const _uuid = Uuid();

enum Difficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  static Difficulty fromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'easy':
        return Difficulty.easy;
      case 'hard':
        return Difficulty.hard;
      case 'medium':
      default:
        return Difficulty.medium;
    }
  }
}

/// Filter/category tags used across the Recipes screen and recipe cards.
enum RecipeTag {
  quick,
  easy,
  medium,
  highProtein,
  vegetarian,
  breakfast,
  lunch,
  dinner,
  dessert;

  String get label {
    switch (this) {
      case RecipeTag.quick:
        return 'Quick';
      case RecipeTag.easy:
        return 'Easy';
      case RecipeTag.medium:
        return 'Medium';
      case RecipeTag.highProtein:
        return 'High Protein';
      case RecipeTag.vegetarian:
        return 'Vegetarian';
      case RecipeTag.breakfast:
        return 'Breakfast';
      case RecipeTag.lunch:
        return 'Lunch';
      case RecipeTag.dinner:
        return 'Dinner';
      case RecipeTag.dessert:
        return 'Dessert';
    }
  }

  static RecipeTag? fromString(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase().replaceAll(' ', '');
    for (final tag in RecipeTag.values) {
      if (tag.name.toLowerCase() == normalized || tag.label.toLowerCase().replaceAll(' ', '') == normalized) {
        return tag;
      }
    }
    return null;
  }
}

/// A single AI-generated (or saved) recipe.
class Recipe extends Equatable {
  final String id;
  final String title;
  final String description;
  final Difficulty difficulty;
  final int cookingTimeMinutes;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final List<CookingStep> steps;
  final List<RecipeTag> tags;
  final String? imageQuery;
  final String? imageUrl;
  final DateTime createdAt;

  Recipe({
    String? id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.cookingTimeMinutes,
    required this.servings,
    required this.ingredients,
    required this.steps,
    this.tags = const [],
    this.imageQuery,
    this.imageUrl,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  List<RecipeIngredient> get availableIngredients =>
      ingredients.where((i) => i.available).toList();

  List<RecipeIngredient> get missingIngredients =>
      ingredients.where((i) => !i.available).toList();

  /// Percentage (0-100) of required ingredients the user already has.
  int get matchPercentage {
    if (ingredients.isEmpty) return 0;
    final availableCount = availableIngredients.length;
    return ((availableCount / ingredients.length) * 100).round();
  }

  /// Safely parses a single recipe object from Groq's JSON response.
  /// Any missing/malformed field falls back to a safe default rather than
  /// throwing — a single bad recipe should never break the whole list.
  factory Recipe.fromAiJson(Map<String, dynamic> json) {
    final rawTitle = json['title'];
    final title = (rawTitle is String && rawTitle.trim().isNotEmpty) ? rawTitle.trim() : 'Untitled recipe';

    final rawDescription = json['description'];
    final description = (rawDescription is String) ? rawDescription.trim() : '';

    final rawTime = json['cookingTimeMinutes'];
    final cookingTime = switch (rawTime) {
      num n => n.toInt(),
      String s => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 20,
      _ => 20,
    };

    final rawServings = json['servings'];
    final servings = switch (rawServings) {
      num n => n.toInt(),
      String s => int.tryParse(s) ?? 2,
      _ => 2,
    };

    final rawIngredients = json['ingredients'];
    final ingredients = <RecipeIngredient>[];
    if (rawIngredients is List) {
      for (final item in rawIngredients) {
        if (item is Map<String, dynamic>) {
          ingredients.add(RecipeIngredient.fromAiJson(item));
        } else if (item is Map) {
          ingredients.add(RecipeIngredient.fromAiJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawSteps = json['instructions'] ?? json['steps'];
    final steps = <CookingStep>[];
    if (rawSteps is List) {
      for (var i = 0; i < rawSteps.length; i++) {
        final item = rawSteps[i];
        if (item is Map<String, dynamic>) {
          steps.add(CookingStep.fromAiJson(item, i + 1));
        } else if (item is Map) {
          steps.add(CookingStep.fromAiJson(Map<String, dynamic>.from(item), i + 1));
        } else if (item is String && item.trim().isNotEmpty) {
          steps.add(CookingStep(order: i + 1, instruction: item.trim()));
        }
      }
    }

    final rawTags = json['tags'];
    final tags = <RecipeTag>[];
    if (rawTags is List) {
      for (final t in rawTags) {
        final parsed = RecipeTag.fromString(t?.toString());
        if (parsed != null) tags.add(parsed);
      }
    }

    final rawImageQuery = json['imageQuery'];
    final imageQuery = (rawImageQuery is String && rawImageQuery.trim().isNotEmpty) ? rawImageQuery.trim() : title;

    return Recipe(
      title: title,
      description: description,
      difficulty: Difficulty.fromString(json['difficulty'] as String?),
      cookingTimeMinutes: cookingTime <= 0 ? 20 : cookingTime,
      servings: servings <= 0 ? 2 : servings,
      ingredients: ingredients,
      steps: steps,
      tags: tags,
      imageQuery: imageQuery,
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'Untitled recipe',
      description: json['description'] as String? ?? '',
      difficulty: Difficulty.fromString(json['difficulty'] as String?),
      cookingTimeMinutes: json['cookingTimeMinutes'] as int? ?? 20,
      servings: json['servings'] as int? ?? 2,
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => RecipeIngredient.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((e) => CookingStep.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => RecipeTag.fromString(e as String?))
          .whereType<RecipeTag>()
          .toList(),
      imageQuery: json['imageQuery'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty.name,
      'cookingTimeMinutes': cookingTimeMinutes,
      'servings': servings,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'steps': steps.map((e) => e.toJson()).toList(),
      'tags': tags.map((e) => e.name).toList(),
      'imageQuery': imageQuery,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Recipe copyWith({String? imageUrl}) {
    return Recipe(
      id: id,
      title: title,
      description: description,
      difficulty: difficulty,
      cookingTimeMinutes: cookingTimeMinutes,
      servings: servings,
      ingredients: ingredients,
      steps: steps,
      tags: tags,
      imageQuery: imageQuery,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        difficulty,
        cookingTimeMinutes,
        servings,
        ingredients,
        steps,
        tags,
        imageQuery,
        imageUrl,
        createdAt,
      ];
}
