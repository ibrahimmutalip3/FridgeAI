import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/fallback_image.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/preferences_providers.dart';
import '../../services/recipe_image_resolver.dart';

class _OnboardingPage {
  final String asset;
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.asset,
    required this.icon,
    required this.title,
    required this.description,
  });
}

const _pages = [
  _OnboardingPage(
    asset: RecipeImageResolver.onboardingHero1,
    icon: Icons.camera_alt_rounded,
    title: 'Turn what\u2019s in your fridge into something delicious.',
    description: 'Snap a photo of your fridge, groceries, or ingredients and let AI take it from there.',
  ),
  _OnboardingPage(
    asset: RecipeImageResolver.onboardingHero2,
    icon: Icons.checklist_rounded,
    title: 'AI recognizes every ingredient.',
    description:
        'FridgeAI identifies what you have, estimates quantities, and lets you fine-tune the list in seconds.',
  ),
  _OnboardingPage(
    asset: RecipeImageResolver.onboardingHero3,
    icon: Icons.restaurant_menu_rounded,
    title: 'Get recipes made for what you already own.',
    description: 'No more wasted food or last-minute grocery runs \u2014 just delicious ideas, instantly.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(preferencesProvider.notifier).completeOnboarding();
    if (mounted) context.go(AppRoutes.home);
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return AnimatedPadding(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        Expanded(
                          child: Hero(
                            tag: 'onboarding_image_$index',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                              child: FallbackImage(
                                assetPath: page.asset,
                                icon: page.icon,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displayMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final active = index == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: active ? 24 : 8,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primaryOrange
                        : AppColors.primaryOrange.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: PrimaryButton(
                label: isLast ? 'Get Started' : 'Next',
                icon: isLast ? Icons.arrow_forward_rounded : null,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
