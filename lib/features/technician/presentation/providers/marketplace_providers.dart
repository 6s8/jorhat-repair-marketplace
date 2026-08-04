import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/job_model.dart';
import '../../data/repositories/supabase_job_parts_repository.dart';
import '../../domain/models/job_part.dart';
import '../../domain/repositories/job_parts_repository.dart';
import 'technician_profile_provider.dart';

// ── Repository ───────────────────────────────────────────────────────────────

final jobPartsRepositoryProvider = Provider<JobPartsRepository>(
  (_) => SupabaseJobPartsRepository(),
);

// ── Active Jobs for job-attachment selector ───────────────────────────────────

class ActiveJobsNotifier extends AsyncNotifier<List<Job>> {
  @override
  Future<List<Job>> build() async {
    final repo = ref.watch(jobPartsRepositoryProvider);
    final techId = ref.watch(currentTechnicianIdProvider);
    return repo.getActiveJobs(techId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(jobPartsRepositoryProvider);
      final techId = ref.read(currentTechnicianIdProvider);
      return repo.getActiveJobs(techId);
    });
  }
}

final activeJobsProvider =
    AsyncNotifierProvider<ActiveJobsNotifier, List<Job>>(
  () => ActiveJobsNotifier(),
);

// ── Selected Job for attach-to-job workflow ───────────────────────────────────

final selectedJobProvider = StateProvider<Job?>((_) => null);

// ── Cart ─────────────────────────────────────────────────────────────────────

class CartItem {
  final String partId;
  final String partName;
  final double technicianPrice;
  final double customerPrice;
  int quantity;

  CartItem({
    required this.partId,
    required this.partName,
    required this.technicianPrice,
    required this.customerPrice,
    this.quantity = 1,
  });

  double get lineTotal => technicianPrice * quantity;
  double get profit => (customerPrice - technicianPrice) * quantity;
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addItem(CartItem item) {
    final idx = state.indexWhere((c) => c.partId == item.partId);
    if (idx >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == idx)
            CartItem(
              partId: state[i].partId,
              partName: state[i].partName,
              technicianPrice: state[i].technicianPrice,
              customerPrice: state[i].customerPrice,
              quantity: state[i].quantity + 1,
            )
          else
            state[i],
      ];
    } else {
      state = [...state, item];
    }
  }

  void removeItem(String partId) {
    state = state.where((c) => c.partId != partId).toList();
  }

  void updateQuantity(String partId, int qty) {
    if (qty <= 0) {
      removeItem(partId);
      return;
    }
    state = [
      for (final c in state)
        if (c.partId == partId)
          CartItem(
            partId: c.partId,
            partName: c.partName,
            technicianPrice: c.technicianPrice,
            customerPrice: c.customerPrice,
            quantity: qty,
          )
        else
          c,
    ];
  }

  void clear() => state = [];

  double get subtotal =>
      state.fold(0.0, (sum, c) => sum + c.lineTotal);

  double get totalProfit =>
      state.fold(0.0, (sum, c) => sum + c.profit);

  int get itemCount => state.fold(0, (sum, c) => sum + c.quantity);
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  () => CartNotifier(),
);

final cartItemCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider.notifier).itemCount,
);

// ── Attach Part to Job ────────────────────────────────────────────────────────

enum AttachStatus { idle, loading, success, failure }

class AttachPartState {
  final AttachStatus status;
  final String? errorMessage;
  final JobPart? attached;

  const AttachPartState({
    this.status = AttachStatus.idle,
    this.errorMessage,
    this.attached,
  });

  AttachPartState copyWith({
    AttachStatus? status,
    String? errorMessage,
    JobPart? attached,
  }) =>
      AttachPartState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        attached: attached ?? this.attached,
      );
}

class AttachPartNotifier extends Notifier<AttachPartState> {
  @override
  AttachPartState build() => const AttachPartState();

  Future<bool> attach({
    required String jobId,
    required String partId,
    required int quantity,
    required double technicianPrice,
    required double customerPrice,
  }) async {
    state = state.copyWith(status: AttachStatus.loading);
    try {
      final repo = ref.read(jobPartsRepositoryProvider);
      final jobPart = await repo.attachPartToJob(
        jobId: jobId,
        partId: partId,
        quantity: quantity,
        technicianPrice: technicianPrice,
        customerPrice: customerPrice,
      );
      state = state.copyWith(status: AttachStatus.success, attached: jobPart);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AttachStatus.failure,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void reset() => state = const AttachPartState();
}

final attachPartProvider =
    NotifierProvider<AttachPartNotifier, AttachPartState>(
  () => AttachPartNotifier(),
);

// ── Fulfillment mode ─────────────────────────────────────────────────────────

enum FulfillmentMode { express, pickup }

final fulfillmentModeProvider =
    StateProvider<FulfillmentMode>((_) => FulfillmentMode.express);
