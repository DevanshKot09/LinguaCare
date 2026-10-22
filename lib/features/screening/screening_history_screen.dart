import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/screening/screening_providers.dart';
import '../../domain/screening/screening_result.dart';
import '../../l10n/app_localizations.dart';

class ScreeningHistoryScreen extends ConsumerWidget {
  final String? childId;
  final String? subjectUid;

  const ScreeningHistoryScreen({
    Key? key,
    this.childId,
    this.subjectUid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = childId != null
        ? ref.watch(childScreeningHistoryProvider(childId!))
        : ref.watch(selfScreeningHistoryProvider(subjectUid ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screeningHistory),
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Text(l10n.noScreeningsYet),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (history.length >= 2) _buildTrendCard(context, history),
              const SizedBox(height: 16),
              ...history.map((result) => _buildHistoryItemCard(context, ref, result)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading history: $err')),
      ),
    );
  }

  Widget _buildTrendCard(BuildContext context, List<ScreeningResult> history) {
    final l10n = AppLocalizations.of(context)!;
    final latest = history[0];
    final previous = history[1];

    String trendText = l10n.trendStable;
    IconData trendIcon = Icons.trending_flat;
    Color trendColor = Colors.blue;

    int riskWeight(String risk) {
      if (risk == 'low') return 0;
      if (risk == 'some_signs') return 1;
      if (risk == 'high') return 2;
      return 1;
    }

    final diff = riskWeight(latest.riskLevel) - riskWeight(previous.riskLevel);
    if (diff < 0) {
      trendText = l10n.trendImproving;
      trendIcon = Icons.trending_up;
      trendColor = Colors.green;
    } else if (diff > 0) {
      trendText = l10n.trendNeedsAttention;
      trendIcon = Icons.trending_down;
      trendColor = Colors.orange;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.trendHeading,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(trendIcon, color: trendColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    trendText,
                    style: TextStyle(color: trendColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItemCard(BuildContext context, WidgetRef ref, ScreeningResult result) {
    final l10n = AppLocalizations.of(context)!;
    final formattedDate = DateFormat.yMMMd().add_jm().format(result.createdAt);

    String riskText = '';
    Color riskColor = Colors.green;
    switch (result.riskLevel) {
      case 'low':
        riskText = 'Low Risk / No strong signs';
        riskColor = Colors.green;
        break;
      case 'some_signs':
        riskText = 'Some signs worth keeping an eye on';
        riskColor = Colors.orange;
        break;
      case 'high':
        riskText = 'Several signs to discuss with professional';
        riskColor = Colors.red;
        break;
      default:
        riskText = 'Not enough information';
        riskColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          riskText,
          style: TextStyle(color: riskColor, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Checked on $formattedDate\nConfidence: ${result.confidence.toUpperCase()}'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(context, ref, result.id),
          tooltip: l10n.deleteResult,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String? sessionId) async {
    if (sessionId == null) return;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteResultConfirmTitle),
        content: Text(l10n.deleteResultConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(screeningRepositoryProvider);
        await repo.deleteScreeningResult(sessionId);
        if (childId != null) {
          ref.invalidate(childScreeningHistoryProvider(childId!));
        } else if (subjectUid != null) {
          ref.invalidate(selfScreeningHistoryProvider(subjectUid!));
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting result: $e')),
        );
      }
    }
  }
}
