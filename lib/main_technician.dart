import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase/supabase_client.dart';
import 'technician/technician_root_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  runApp(const ProviderScope(child: TechnicianRootApp()));
}
