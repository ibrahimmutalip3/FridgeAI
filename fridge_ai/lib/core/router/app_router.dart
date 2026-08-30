import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cooking/cooking_mode_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/ingredients/ingredient_results_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/pantry/my_kitchen_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/recipes/recipe_details_screen.dart';
import '../../features/recipes/recipe_results_screen.dart';
import '../../features/recipes/recipes_screen.dart';
import '../../features/scanner/ai_analysis_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../models/recipe.dart';
import '../../providers/preferences_providers.dart';
import 'app_page_transitions.dart';
import 'app_routes.dart';

/// A [Listenable] that notifies GoRouter to re-evaluate `redirect` whenever
/// the onboarding-complete flag flips, so the very first navigation
/// decision (onboarding vs. home) reacts correctly without a manual
/// `context.go` race at startup.
class _OnboardingRefreshListenable extends ChangeNotifier {
  _OnboardingRefreshListenable(this._ref) {
    _ref.listen(preferencesProvider, (previous, next) {
      if (previous?.onboardingComplete != next.onboardingComplete) {
        notifyListeners();
      }
    });
  }

  final Ref _ref;
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// The app-wide [GoRouter], provided via Riverpod so it can read
/// [preferencesProvider] for the onboarding redirect and rebuild only when
/// necessary (see [_OnboardingRefreshListenable]).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _OnboardingRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final onboardingComplete = ref.read(preferencesProvider).onboardingComplete;
      final goingToSplash = state.matchedLocation == AppRoutes.splash;
      final goingToOnboarding = state.matchedLocation == AppRoutes.onboarding;

      // The splash screen owns its own exit navigation (it plays a full
      // morph-out animation before calling context.go itself), so the
      // redirect must never preempt it — otherwise the animation gets cut
      // short by an instant jump straight to onboarding/home.
      if (goingToSplash) {
        return null;
      }
      if (!onboardingComplete && !goingToOnboarding) {
        return AppRoutes.onboarding;
      }
      if (onboardingComplete && goingToOnboarding) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        // A soft cross-fade rather than the platform's default slide — this
        // route is most often entered right as the splash morphs out, and a
        // fade keeps that a single continuous motion instead of a hard cut.
        pageBuilder: (context, state) =>
            AppPageTransitions.fade(state: state, child: const OnboardingScreen()),
      ),

      // Bottom-navigation shell: Home / Recipes / Kitchen / Profile.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: AppRoutes.recipesTab,
                builder: (context, state) => const RecipesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: AppRoutes.myKitchen,
                builder: (context, state) => const MyKitchenScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: AppRoutes.profileTab,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Scan flow — pushed full-screen on top of the shell.
      // The scanner itself is a modal tool takeover (slide up from the
      // bottom); the AI analysis → results steps are the app's key "AI
      // moment" and use the more expressive reveal transition so the
      // experience of watching the app understand your fridge actually
      // feels like something happening, not just another page push.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.scanner,
        pageBuilder: (context, state) =>
            AppPageTransitions.modalUp(state: state, child: const ScannerScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.aiAnalysis,
        pageBuilder: (context, state) => AppPageTransitions.reveal(
          state: state,
          child: AiAnalysisScreen(imageFile: state.extra as File),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.ingredientResults,
        pageBuilder: (context, state) =>
            AppPageTransitions.reveal(state: state, child: const IngredientResultsScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.recipeResults,
        pageBuilder: (context, state) =>
            AppPageTransitions.reveal(state: state, child: const RecipeResultsScreen()),
      ),

      // Recipe details / cooking mode — routine forward navigation.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.recipeDetails,
        pageBuilder: (context, state) => AppPageTransitions.forward(
          state: state,
          child: RecipeDetailsScreen(recipe: state.extra as Recipe),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.cookingMode,
        pageBuilder: (context, state) => AppPageTransitions.modalUp(
          state: state,
          child: CookingModeScreen(recipe: state.extra as Recipe),
        ),
      ),
    ],
    errorBuilder: (context, state) => const _RouteErrorScreen(),
  );
});

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40),
              const SizedBox(height: 12),
              Text(
                "We couldn't find that page.",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
