import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// How urgently an ingredient's [Ingredient.expirationDate] should be
/// surfaced in the UI. Deliberately coarse (three buckets) so the visual
/// treatment stays calm — this drives a small pill/label, not a full
/// traffic-light system.
enum FreshnessUrgency {
  /// No expiration date set, or it's comfortably far away (> 2 days).
  none,

  /// Expires today or tomorrow — worth a gentle nudge.
  soon,

  /// Already expired.
  expired,
}

/// Broad category used to organize the user's pantry (My Kitchen screen).
enum IngredientCategory {
  vegetables,
  meat,
  dairy,
  fruits,
  grains,
  pantry;

  String get label {
    switch (this) {
      case IngredientCategory.vegetables:
        return 'Vegetables';
      case IngredientCategory.meat:
        return 'Meat';
      case IngredientCategory.dairy:
        return 'Dairy';
      case IngredientCategory.fruits:
        return 'Fruits';
      case IngredientCategory.grains:
        return 'Grains';
      case IngredientCategory.pantry:
        return 'Pantry';
    }
  }

  static IngredientCategory fromString(String? value) {
    if (value == null) return IngredientCategory.pantry;
    final normalized = value.trim().toLowerCase();
    for (final category in IngredientCategory.values) {
      if (category.name == normalized || category.label.toLowerCase() == normalized) {
        return category;
      }
    }
    // Light heuristic fallback for common AI phrasing variants.
    if (normalized.contains('veg')) return IngredientCategory.vegetables;
    if (normalized.contains('meat') || normalized.contains('poultry') || normalized.contains('fish')) {
      return IngredientCategory.meat;
    }
    if (normalized.contains('dairy') || normalized.contains('milk') || normalized.contains('cheese')) {
      return IngredientCategory.dairy;
    }
    if (normalized.contains('fruit')) return IngredientCategory.fruits;
    if (normalized.contains('grain') || normalized.contains('bread') || normalized.contains('rice')) {
      return IngredientCategory.grains;
    }
    return IngredientCategory.pantry;
  }
}

/// A single ingredient the user has (detected by AI or added manually).
class Ingredient extends Equatable {
  final String id;
  final String name;
  final String quantity;
  final IngredientCategory category;
  final DateTime? expirationDate;
  final DateTime addedAt;
  final String? imageQuery;

  Ingredient({
    String? id,
    required this.name,
    required this.quantity,
    this.category = IngredientCategory.pantry,
    this.expirationDate,
    DateTime? addedAt,
    this.imageQuery,
  })  : id = id ?? _uuid.v4(),
        addedAt = addedAt ?? DateTime.now();

  /// Whole-day difference between [expirationDate] and today (negative if
  /// already past). Null when no expiration date is set.
  int? get daysUntilExpiration {
    final expiration = expirationDate;
    if (expiration == null) return null;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final startOfExpiration = DateTime(expiration.year, expiration.month, expiration.day);
    return startOfExpiration.difference(startOfToday).inDays;
  }

  /// Coarse urgency bucket derived from [daysUntilExpiration], used to
  /// decide whether/how to show a freshness hint on ingredient cards.
  FreshnessUrgency get freshnessUrgency {
    final days = daysUntilExpiration;
    if (days == null) return FreshnessUrgency.none;
    if (days < 0) return FreshnessUrgency.expired;
    if (days <= 1) return FreshnessUrgency.soon;
    return FreshnessUrgency.none;
  }

  /// Short, human-readable label for the current [freshnessUrgency] (e.g.
  /// "Expired", "Expires today", "Expires tomorrow"). Empty when there's
  /// nothing worth showing.
  String get freshnessLabel {
    final days = daysUntilExpiration;
    if (days == null) return '';
    switch (freshnessUrgency) {
      case FreshnessUrgency.expired:
        return days == -1 ? 'Expired yesterday' : 'Expired';
      case FreshnessUrgency.soon:
        return days == 0 ? 'Expires today' : 'Expires tomorrow';
      case FreshnessUrgency.none:
        return '';
    }
  }

  Ingredient copyWith({
    String? name,
    String? quantity,
    IngredientCategory? category,
    DateTime? expirationDate,
    bool clearExpirationDate = false,
    String? imageQuery,
  }) {
    return Ingredient(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      expirationDate: clearExpirationDate ? null : (expirationDate ?? this.expirationDate),
      addedAt: addedAt,
      imageQuery: imageQuery ?? this.imageQuery,
    );
  }

  /// Safely parses a single ingredient from an AI (Groq) JSON object.
  /// Falls back to sensible defaults if fields are missing or malformed —
  /// AI responses must never crash the app.
  factory Ingredient.fromAiJson(Map<String, dynamic> json) {
    final rawName = json['name'];
    final name = (rawName is String && rawName.trim().isNotEmpty) ? rawName.trim() : 'Unknown item';

    final rawQuantity = json['quantity'];
    final quantity = switch (rawQuantity) {
      String s when s.trim().isNotEmpty => s.trim(),
      num n => n.toString(),
      _ => '1',
    };

    return Ingredient(
      name: name,
      quantity: quantity,
      category: IngredientCategory.fromString(json['category'] as String?),
      imageQuery: (json['name'] is String) ? rawName as String : null,
    );
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Unknown item',
      quantity: json['quantity'] as String? ?? '1',
      category: IngredientCategory.fromString(json['category'] as String?),
      expirationDate: json['expirationDate'] != null
          ? DateTime.tryParse(json['expirationDate'] as String)
          : null,
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      imageQuery: json['imageQuery'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'category': category.name,
      'expirationDate': expirationDate?.toIso8601String(),
      'addedAt': addedAt.toIso8601String(),
      'imageQuery': imageQuery,
    };
  }

  @override
  List<Object?> get props => [id, name, quantity, category, expirationDate, addedAt, imageQuery];
}
