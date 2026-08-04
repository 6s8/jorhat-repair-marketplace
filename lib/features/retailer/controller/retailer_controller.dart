import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/shared_marketplace_store.dart';
import '../models/spare_part_model.dart';
import '../repositories/retailer_repository.dart';

class RetailerState {
  final bool isLoading;
  final bool isSaving;
  final List<SparePart> parts;
  final String? error;

  RetailerState({
    this.isLoading = false,
    this.isSaving = false,
    this.parts = const [],
    this.error,
  });

  RetailerState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<SparePart>? parts,
    String? error,
  }) {
    return RetailerState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      parts: parts ?? this.parts,
      error: error,
    );
  }
}

final retailerControllerProvider =
    StateNotifierProvider<RetailerController, RetailerState>((ref) {
  final repository = ref.watch(retailerRepositoryProvider);
  return RetailerController(repository, ref);
});

class RetailerController extends StateNotifier<RetailerState> {
  final RetailerRepository _repository;
  final Ref _ref;
  StreamSubscription<List<SparePart>>? _subscription;

  RetailerController(this._repository, this._ref) : super(RetailerState()) {
    _initRealtimeSubscription();
  }

  void _initRealtimeSubscription() {
    state = state.copyWith(isLoading: true, error: null);
    _subscription = _repository.watchParts().listen(
      (remoteParts) {
        state = state.copyWith(isLoading: false, parts: remoteParts, error: null);
        _ref.read(sharedMarketplaceStoreProvider.notifier).setParts(remoteParts);
      },
      onError: (error) {
        state = state.copyWith(isLoading: false, error: error.toString());
      },
    );
  }

  Future<void> addPart(SparePart part) async {
    final previousParts = state.parts;
    final updatedParts = [part, ...state.parts.where((p) => p.id != part.id)];
    state = state.copyWith(isSaving: true, parts: updatedParts, error: null);
    _ref.read(sharedMarketplaceStoreProvider.notifier).addOrUpdatePart(part);

    try {
      await _repository.addPart(part);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false, parts: previousParts, error: e.toString());
      _ref.read(sharedMarketplaceStoreProvider.notifier).setParts(previousParts);
    }
  }

  Future<void> updatePart(SparePart part) async {
    final previousParts = state.parts;
    final updatedParts = state.parts.map((p) => p.id == part.id ? part : p).toList();
    state = state.copyWith(isSaving: true, parts: updatedParts, error: null);
    _ref.read(sharedMarketplaceStoreProvider.notifier).addOrUpdatePart(part);

    try {
      await _repository.updatePart(part);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false, parts: previousParts, error: e.toString());
      _ref.read(sharedMarketplaceStoreProvider.notifier).setParts(previousParts);
    }
  }

  Future<void> deletePart(String partId) async {
    final previousParts = state.parts;
    final updatedParts = state.parts.where((p) => p.id != partId).toList();
    state = state.copyWith(isSaving: true, parts: updatedParts, error: null);
    _ref.read(sharedMarketplaceStoreProvider.notifier).removePart(partId);

    try {
      await _repository.deletePart(partId);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false, parts: previousParts, error: e.toString());
      _ref.read(sharedMarketplaceStoreProvider.notifier).setParts(previousParts);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
