import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/supabase/supabase_client.dart';
import 'customer/customer_root_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // Fixes OAuth loop by preventing hash routing interference
  await initializeSupabase();
  runApp(const ProviderScope(child: CustomerRootApp()));
}
