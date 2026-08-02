import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/technician/presentation/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase SDK if valid URL and Anon Key are configured
  if (SupabaseConfig.supabaseUrl != 'https://your-supabase-project-id.supabase.co') {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  runApp(
    const ProviderScope(
      child: JorhatRepairApp(),
    ),
  );
}

class JorhatRepairApp extends StatelessWidget {
  const JorhatRepairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
