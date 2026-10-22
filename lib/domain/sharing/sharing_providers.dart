import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_sharing_repository.dart';
import 'sharing_models.dart';
import 'sharing_repository.dart';

final sharingRepositoryProvider = Provider<SharingRepository>((ref) {
  return SupabaseSharingRepository();
});

final myLinksProvider = FutureProvider.family<List<LinkInfo>, bool>((ref, includeInactive) async {
  final repo = ref.watch(sharingRepositoryProvider);
  return repo.listMyLinks(includeInactive: includeInactive);
});

final sharedSummaryProvider = FutureProvider.family<SharedSummary, String>((ref, linkId) async {
  final repo = ref.watch(sharingRepositoryProvider);
  return repo.getSharedSummary(linkId);
});

final accessLogProvider = FutureProvider.family<List<AccessLogEntry>, String?>((ref, childId) async {
  final repo = ref.watch(sharingRepositoryProvider);
  return repo.listAccessLog(childId: childId);
});
