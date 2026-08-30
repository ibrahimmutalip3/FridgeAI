/// Centralized route path constants — the single source of truth for
/// navigation so screens never hardcode path strings inline.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  // Bottom-nav shell branches
  static const String home = '/home';
  static const String scannerTab = '/scanner-tab';
  static const String recipesTab = '/recipes';
  static const String profileTab = '/profile';

  // Scan flow (pushed on top of the shell)
  static const String scanner = '/scanner';
  static const String aiAnalysis = '/ai-analysis';
  static const String ingredientResults = '/ingredient-results';
  static const String recipeResults = '/recipe-results';

  // Recipe details / cooking
  static const String recipeDetails = '/recipe-details';
  static const String cookingMode = '/cooking-mode';

  // Pantry
  static const String myKitchen = '/my-kitchen';
}
