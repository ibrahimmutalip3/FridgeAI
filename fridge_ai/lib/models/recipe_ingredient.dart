import 'package:equatable/equatable.dart';

/// An ingredient required by a recipe, flagged as available or missing
/// relative to the user's current pantry at generation time.
class RecipeIngredient extends Equatable {
  final String name;
  final String quantity;
  final bool available;

  const RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.available,
  });

  factory RecipeIngredient.fromAiJson(Map<String, dynamic> json) {
    final rawName = json['name'];
    final name = (rawName is String && rawName.trim().isNotEmpty) ? rawName.trim() : 'Ingredient';

    final rawQuantity = json['quantity'];
    final quantity = switch (rawQuantity) {
      String s when s.trim().isNotEmpty => s.trim(),
      num n => n.toString(),
      _ => '',
    };

    final rawAvailable = json['available'];
    final available = switch (rawAvailable) {
      bool b => b,
      String s => s.toLowerCase() == 'true',
      _ => false,
    };

    return RecipeIngredient(name: name, quantity: quantity, available: available);
  }

  RecipeIngredient copyWithAvailable(bool available) {
    return RecipeIngredient(name: name, quantity: quantity, available: available);
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String? ?? 'Ingredient',
      quantity: json['quantity'] as String? ?? '',
      available: json['available'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'available': available,
      };

  @override
  List<Object?> get props => [name, quantity, available];
}
