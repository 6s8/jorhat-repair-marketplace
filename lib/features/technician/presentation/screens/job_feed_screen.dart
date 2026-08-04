import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/accept_job_controller.dart';
import '../../../../providers/realtime_job_list_provider.dart';
import '../widgets/empty_jobs_widget.dart';
import '../widgets/job_card.dart';
import 'job_feed_map_view.dart';

/// Main Realtime Technician Dispatch Feed Screen — with List and Map views.
class JobFeedScreen extends ConsumerStatefulWidget {
  final String currentTechnicianId;

  const JobFeedScreen({
    super.key,
    this.currentTechnicianId = '00000000-0000-4000-8000-000000000001',
  });

  @override
  ConsumerState<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends ConsumerState<JobFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to acceptState changes to navigate or display error snackbars
    ref.listen<AcceptJobState>(acceptJobControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(acceptJobControllerProvider.notifier).clearError();
      }

      if (next.acceptedJob != null &&
          previous?.acceptedJob != next.acceptedJob) {
        context.push('/job-detail', extra: next.acceptedJob);
      }
    });

    return Column(
      children: [
        // ── List / Map tab bar ────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
          ),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'List'),
              Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'Map'),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // ── Tab content ───────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ListFeedView(
                  technicianId: widget.currentTechnicianId),
              JobFeedMapView(
                  technicianId: widget.currentTechnicianId),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── List Feed View (previous JobFeedScreen body) ─────────────────────────────
class _ListFeedView extends ConsumerWidget {
  final String technicianId;
  const _ListFeedView({required this.technicianId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncJobs = ref.watch(realtimeJobListProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(realtimeJobListProvider.notifier).refresh(),
      child: asyncJobs.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading jobs: ${error.toString()}',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(realtimeJobListProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return EmptyJobsWidget(
              onRefresh: () =>
                  ref.read(realtimeJobListProvider.notifier).refresh(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return JobCard(
                key: ValueKey(job.id),
                job: job,
                currentTechnicianId: technicianId,
                onAcceptSuccess: () =>
                    context.push('/job-detail', extra: job),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .slideY(
                      begin: 0.15,
                      end: 0,
                      duration: 300.ms,
                      curve: Curves.easeOut);
            },
          );
        },
      ),
    );
  }
}
