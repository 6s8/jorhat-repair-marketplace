import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/app_scroll_behavior.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/retailer/presentation/screens/retailer_dashboard_screen.dart';

final retailerRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const RetailerDashboardScreen(),
    ),
  ],
);

class RetailerRootApp extends ConsumerWidget {
  const RetailerRootApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Fixly Retailer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: themeMode,
      scrollBehavior: const AppStretchScrollBehavior(),
      routerConfig: retailerRouter,
      builder: (context, child) {
        return AuthGate(
          targetRole: 'retailer',
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
