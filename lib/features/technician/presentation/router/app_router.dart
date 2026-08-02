import 'package:go_router/go_router.dart';
import '../../../../models/job_model.dart';
import '../../../main_navigation/presentation/main_navigation_screen.dart';
import '../screens/job_detail_screen.dart';

/// App router configuration using GoRouter.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: '/job-detail',
      builder: (context, state) {
        final job = state.extra as Job?;
        return JobDetailScreen(job: job);
      },
    ),
  ],
);
