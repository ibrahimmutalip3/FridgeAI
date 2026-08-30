import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'models/user_preferences.dart';
import 'providers/preferences_providers.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage must be ready before any provider reads preferences or
  // pantry data synchronously during widget construction.
  await StorageService.instance.init();

  runApp(const ProviderScope(child: FridgeAiApp()));
}

class FridgeAiApp extends ConsumerWidget {
  const FridgeAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(preferencesProvider).themeMode;

    return MaterialApp.router(
      title: 'FridgeAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _toFlutterThemeMode(themeMode),
      routerConfig: router,
    );
  }

  ThemeMode _toFlutterThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
