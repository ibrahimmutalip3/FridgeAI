import 'package:equatable/equatable.dart';
import 'ingredient.dart';

/// Result of sending a photo to Groq for food/ingredient recognition.
///
/// [success] is false when the AI could not identify any food, the response
/// was malformed, or the request failed — the UI uses this to show a
/// friendly "couldn't recognize food" state instead of a crash.
class ScanResult extends Equatable {
  final bool success;
  final List<Ingredient> ingredients;
  final String? errorMessage;
  final String? rawNote;

  const ScanResult({
    required this.success,
    this.ingredients = const [],
    this.errorMessage,
    this.rawNote,
  });

  factory ScanResult.empty(String message) => ScanResult(success: false, errorMessage: message);

  /// Safely parses the top-level AI JSON payload for a scan.
  /// Expected shape:
  /// { "ingredients": [ { "name": "...", "quantity": "...", "category": "..." }, ... ], "note": "..." }
  factory ScanResult.fromAiJson(Map<String, dynamic> json) {
    final rawList = json['ingredients'];
    if (rawList is! List || rawList.isEmpty) {
      return const ScanResult(
        success: false,
        errorMessage: "I couldn't spot any food in that photo. Try a clearer shot?",
      );
    }

    final ingredients = <Ingredient>[];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        ingredients.add(Ingredient.fromAiJson(item));
      } else if (item is Map) {
        ingredients.add(Ingredient.fromAiJson(Map<String, dynamic>.from(item)));
      }
    }

    if (ingredients.isEmpty) {
      return const ScanResult(
        success: false,
        errorMessage: "I couldn't spot any food in that photo. Try a clearer shot?",
      );
    }

    return ScanResult(
      success: true,
      ingredients: ingredients,
      rawNote: json['note'] as String?,
    );
  }

  @override
  List<Object?> get props => [success, ingredients, errorMessage, rawNote];
}
