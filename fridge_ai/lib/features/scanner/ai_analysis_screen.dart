import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/pantry_providers.dart';
import 'widgets/liquid_scan_animation.dart';

class AiAnalysisScreen extends ConsumerStatefulWidget {
  const AiAnalysisScreen({super.key, required this.imageFile});

  final File imageFile;

  @override
  ConsumerState<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends ConsumerState<AiAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _analyze());
  }

  Future<void> _analyze() async {
    await ref.read(scanFlowProvider.notifier).analyze(widget.imageFile);
    if (!mounted) return;

    final status = ref.read(scanFlowProvider).status;
    if (status == ScanFlowStatus.success) {
      context.pushReplacement(AppRoutes.ingredientResults);
    }
  }

  void _retry() {
    ref.read(scanFlowProvider.notifier).reset();
    _analyze();
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(scanFlowProvider);
    final theme = Theme.of(context);
    final showFailure = flowState.status == ScanFlowStatus.noFoodDetected ||
        flowState.status == ScanFlowStatus.error;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(widget.imageFile, fit: BoxFit.cover),
                            if (!showFailure) const LiquidScanAnimation(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // The failure state replaces the "AI is thinking" copy
                    // entirely (different icon, different message, an
                    // action button) — a cross-fade keeps that swap from
                    // reading as a jarring content pop.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: showFailure
                          ? EmptyState(
                              key: const ValueKey('failure'),
                              icon: Icons.search_off_rounded,
                              title: 'Couldn\u2019t recognize that',
                              message: flowState.errorMessage ??
                                  'I couldn\u2019t identify any food in that photo. Try a clearer, well-lit shot.',
                              actionLabel: 'Try Again',
                              onAction: _retry,
                            )
                          : Column(
                              key: const ValueKey('analyzing'),
                              children: [
                                Text(
                                  'AI is identifying your food\u2026',
                                  style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'This usually takes a few seconds.',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (showFailure)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: TextButton(
                  onPressed: () => context.pop(),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryOrange),
                  child: Text(
                    'Scan a different photo',
                    style: theme.textTheme.labelLarge?.copyWith(color: AppColors.primaryOrange),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
