import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/supabase/supabase_client.dart';
import 'retailer/retailer_root_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await initializeSupabase();
  runApp(const ProviderScope(child: RetailerRootApp()));
}
