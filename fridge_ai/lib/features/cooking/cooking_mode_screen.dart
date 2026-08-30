import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/cooking_step.dart';
import '../../models/recipe.dart';
import '../../providers/recipe_providers.dart';
import 'widgets/step_timer.dart';

/// Distraction-free, full-screen step-by-step cooking guide. Shows one
/// instruction at a time with a progress indicator and an optional
/// countdown timer for steps that involve waiting.
class CookingModeScreen extends ConsumerStatefulWidget {
  const CookingModeScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends ConsumerState<CookingModeScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _markedCooked = false;

  List<CookingStep> get _steps => widget.recipe.steps;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _steps.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (!_markedCooked) {
      _markedCooked = true;
      await ref.read(favoritesControllerProvider).markCooked();
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _FinishedSheet(
        onDone: () {
          Navigator.of(context).pop();
          // Pop cooking mode + recipe details back to the results/home screen.
          var popped = 0;
          while (context.canPop() && popped < 2) {
            context.pop();
            popped++;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cooking Mode')),
        body: const Center(child: Text('This recipe has no steps.')),
      );
    }

    final isLastStep = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      widget.recipe.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 48), // balances the close button
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    // Eases toward the new value instead of jumping —
                    // matches the "in-place state changes" motion budget
                    // (≤300ms) so stepping forward/back reads as continuous
                    // progress rather than a discrete counter tick.
                    child: _AnimatedStepProgress(
                      value: (_currentStep + 1) / _steps.length,
                      trackColor: theme.dividerColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'STEP ${_currentStep + 1} OF ${_steps.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryOrangeDark,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) => setState(() => _currentStep = index),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          step.instruction,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall ??
                              theme.textTheme.displayMedium,
                        ),
                        if (step.timerSeconds != null) ...[
                          const SizedBox(height: AppSpacing.xl),
                          StepTimer(seconds: step.timerSeconds!),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentStep == 0 ? null : () => _goTo(_currentStep - 1),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      onPressed: isLastStep ? _finish : () => _goTo(_currentStep + 1),
                      icon: Icon(
                        isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                      label: Text(isLastStep ? 'Finish' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animates [LinearProgressIndicator]'s value smoothly from whatever it
/// last was to the new [value], instead of [LinearProgressIndicator]
/// jumping instantly the way it does with a plain `double`. Explicit
/// [AnimationController] (not [TweenAnimationBuilder]) specifically so the
/// tween's `begin` can track the *previous* rendered value on each change,
/// rather than always animating in from 0.
class _AnimatedStepProgress extends StatefulWidget {
  const _AnimatedStepProgress({required this.value, required this.trackColor});

  final double value;
  final Color trackColor;

  @override
  State<_AnimatedStepProgress> createState() => _AnimatedStepProgressState();
}

class _AnimatedStepProgressState extends State<_AnimatedStepProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late Animation<double> _animation = AlwaysStoppedAnimation(widget.value);

  @override
  void initState() {
    super.initState();
    _animation = Tween(begin: widget.value, end: widget.value).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _AnimatedStepProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween(begin: _animation.value, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => LinearProgressIndicator(
        value: _animation.value,
        minHeight: 6,
        backgroundColor: widget.trackColor,
        valueColor: const AlwaysStoppedAnimation(AppColors.primaryOrange),
      ),
    );
  }
}

class _FinishedSheet extends StatelessWidget {
  const _FinishedSheet({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A rare, celebratory moment (finishing a recipe) earns a bit more
          // delight than the app's usual restrained motion — a soft
          // overshoot scale-in on the checkmark, once, when the sheet first
          // appears. Same controlled-overshoot approach as the splash
          // logo's entrance (a short TweenSequence, not a bouncy curve).
          TweenAnimationBuilder<double>(
            tween: TweenSequence<double>([
              TweenSequenceItem(
                tween: Tween(begin: 0.5, end: 1.08).chain(CurveTween(curve: Curves.easeOutCubic)),
                weight: 70,
              ),
              TweenSequenceItem(
                tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
                weight: 30,
              ),
            ]),
            duration: const Duration(milliseconds: 420),
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.secondaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Bon appétit!', style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nice work — enjoy your meal.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onPressed: onDone,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
