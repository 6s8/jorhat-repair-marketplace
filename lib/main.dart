import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/router/app_router.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/app_scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // Fixes web OAuth redirect loops by avoiding hash URL fragments
  await initializeSupabase();
  runApp(const ProviderScope(child: FixlyApp()));
}

/// Root Application Widget using unified GoRouter role-based routing.
class FixlyApp extends ConsumerWidget {
  const FixlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Fixly - Assam Repair & Parts Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: themeMode,
      scrollBehavior: const AppStretchScrollBehavior(),
      routerConfig: router,
    );
  }
}
