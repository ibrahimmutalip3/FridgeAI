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

  /// Normalized form of [name] used to decide whether two ingredients are
  /// "the same" for merge purposes (e.g. when the same item is scanned
  /// twice) — case/whitespace-insensitive and ignores a trailing plural 's'
  /// so "Tomato" and "tomatoes" still match.
  String get _mergeKey {
    var normalized = name.trim().toLowerCase();
    if (normalized.endsWith('es') && normalized.length > 3) {
      normalized = normalized.substring(0, normalized.length - 2);
    } else if (normalized.endsWith('s') && normalized.length > 2) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  /// Whether [other] represents the same real-world item as this one (same
  /// name, ignoring case/whitespace/simple plurals) and so should be merged
  /// into a single pantry card instead of shown as a separate duplicate.
  bool isSameItemAs(Ingredient other) => _mergeKey == other._mergeKey;

  /// Combines this ingredient with a newly-scanned/added [other] of the same
  /// item into a single merged entry, instead of the two existing side by
  /// side as duplicate cards. Keeps this ingredient's id/category/expiration
  /// (the existing pantry entry "wins" on everything except quantity), and
  /// adds the quantities together when both are parseable numbers sharing
  /// a unit (e.g. "2" + "1" -> "3", "200 g" + "100 g" -> "300 g"). When the
  /// quantities can't be combined numerically (different/no units, or
  /// non-numeric text like "a bunch"), falls back to a combined label like
  /// "2 + 1 bottle" so no information is silently dropped.
  Ingredient mergedWith(Ingredient other) {
    return copyWith(quantity: _combineQuantities(quantity, other.quantity));
  }

  static final _quantityPattern = RegExp(r'^\s*([0-9]+(?:\.[0-9]+)?)\s*(.*?)\s*$');

  static String _combineQuantities(String a, String b) {
    final matchA = _quantityPattern.firstMatch(a);
    final matchB = _quantityPattern.firstMatch(b);
    if (matchA != null && matchB != null) {
      final unitA = matchA.group(2) ?? '';
      final unitB = matchB.group(2) ?? '';
      if (unitA.toLowerCase() == unitB.toLowerCase()) {
        final numA = double.tryParse(matchA.group(1)!);
        final numB = double.tryParse(matchB.group(1)!);
        if (numA != null && numB != null) {
          final sum = numA + numB;
          final formatted = sum == sum.roundToDouble() ? sum.toInt().toString() : sum.toString();
          return unitA.isEmpty ? formatted : '$formatted $unitA';
        }
      }
    }
    if (a.trim() == b.trim()) return a.trim();
    return '$a + $b';
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
