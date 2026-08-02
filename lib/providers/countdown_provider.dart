import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ticker provider emitting periodic events every 1 second
final countdownTickerProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (computationCount) => computationCount);
});
