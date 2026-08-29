import 'package:equatable/equatable.dart';

/// A single numbered instruction within a recipe, optionally carrying a
/// suggested timer duration (e.g. "Simmer for 10 minutes" -> 600 seconds)
/// so Cooking Mode can offer a one-tap timer.
class CookingStep extends Equatable {
  final int order;
  final String instruction;
  final int? timerSeconds;

  const CookingStep({
    required this.order,
    required this.instruction,
    this.timerSeconds,
  });

  factory CookingStep.fromAiJson(Map<String, dynamic> json, int fallbackOrder) {
    final rawInstruction = json['instruction'];
    final instruction = (rawInstruction is String && rawInstruction.trim().isNotEmpty)
        ? rawInstruction.trim()
        : 'Continue with the next step.';

    final rawOrder = json['order'];
    final order = switch (rawOrder) {
      num n => n.toInt(),
      String s => int.tryParse(s) ?? fallbackOrder,
      _ => fallbackOrder,
    };

    final rawTimer = json['timerSeconds'];
    final timerSeconds = switch (rawTimer) {
      num n when n > 0 => n.toInt(),
      String s => int.tryParse(s),
      _ => null,
    };

    return CookingStep(order: order, instruction: instruction, timerSeconds: timerSeconds);
  }

  factory CookingStep.fromJson(Map<String, dynamic> json) {
    return CookingStep(
      order: json['order'] as int? ?? 0,
      instruction: json['instruction'] as String? ?? '',
      timerSeconds: json['timerSeconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'order': order,
        'instruction': instruction,
        'timerSeconds': timerSeconds,
      };

  @override
  List<Object?> get props => [order, instruction, timerSeconds];
}
