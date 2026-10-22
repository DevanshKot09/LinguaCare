import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/screening_repository_impl.dart';
import 'instrument.dart';
import 'screening_repository.dart';
import 'screening_result.dart';

final screeningRepositoryProvider = Provider<ScreeningRepository>((ref) {
  return ScreeningRepositoryImpl();
});

final instrumentProvider = FutureProvider.family<Instrument, String>((ref, instrumentId) async {
  final repo = ref.watch(screeningRepositoryProvider);
  return repo.loadInstrument(instrumentId);
});

final childScreeningHistoryProvider = FutureProvider.family<List<ScreeningResult>, String>((ref, childId) async {
  final repo = ref.watch(screeningRepositoryProvider);
  return repo.getScreeningHistoryForChild(childId);
});

final selfScreeningHistoryProvider = FutureProvider.family<List<ScreeningResult>, String>((ref, subjectUid) async {
  final repo = ref.watch(screeningRepositoryProvider);
  return repo.getScreeningHistoryForSelf(subjectUid);
});
