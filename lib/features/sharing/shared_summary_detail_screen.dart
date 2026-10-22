import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/sharing/sharing_providers.dart';
import '../../domain/sharing/sharing_models.dart';
import '../export/export_action_widget.dart';
import '../export/summary_document.dart';

class SharedSummaryDetailScreen extends ConsumerWidget {
  final String linkId;
  final String childName;

  const SharedSummaryDetailScreen({
    super.key,
    required this.linkId,
    required this.childName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(sharedSummaryProvider(linkId));

    return Scaffold(
      appBar: AppBar(title: Text('$childName - Shared Summary')),
      body: SafeArea(
        child: summaryAsync.when(
          data: (summary) => _buildSummaryContent(context, ref, summary),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load shared summary: $e'))),
        ),
      ),
    );
  }

  Widget _buildSummaryContent(BuildContext context, WidgetRef ref, SharedSummary summary) {
    final observations = summary.observations.where((o) => o['private'] != true).toList();
    final goals = summary.goals;
    final showNotes = summary.scope == 'progress_notes';
    const sessionRole = 'specialist';

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Shared by the family. Read-only.', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'LinguaCare supports language development. It does not diagnose.',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              Text('Active Scope: ${summary.scope.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final screenings = summary.screeningSessions.map((s) => SummaryScreeningItem(
                    date: s['created_at']?.toString().split('T').first ?? '',
                    instrumentVersion: s['instrument_version']?.toString() ?? 'v1',
                    riskWording: s['risk_level']?.toString() ?? 'Unknown',
                    domainLevels: [],
                    alsoCheckFlags: [],
                    urgentNoticeTriggered: false,
                    confidence: 'High',
                    isPrototype: s['instrument_status'] != 'published',
                  )).toList();

                  final practices = summary.activitySessions.map((a) => SummaryPracticeItem(
                    domain: a['domain']?.toString() ?? 'General',
                    summaryText: 'Activity practice completed',
                    durationMinutes: (a['duration_s'] ?? 0) ~/ 60,
                    supportLevel: a['support_level']?.toString() ?? 'independent',
                    date: a['date']?.toString() ?? '',
                  )).toList();

                  final goalList = summary.goals.map((g) => SummaryGoalItem(
                    description: g['description']?.toString() ?? '',
                    domain: g['domain']?.toString() ?? 'General',
                    status: g['status']?.toString() ?? 'active',
                    progress: g['progress'] ?? 0,
                  )).toList();

                  final obsList = summary.observations.map((o) => SummaryObservationItem(
                    note: o['note']?.toString() ?? '',
                    setting: o['setting']?.toString() ?? 'General',
                    date: o['created_at']?.toString().split('T').first ?? '',
                    isPrivate: o['private'] == true,
                    isOwnObservation: false,
                  )).toList();

                  showExportSummaryDialog(
                    context: context,
                    role: sessionRole,
                    scope: summary.scope,
                    subjectNickname: childName,
                    subjectAgeBand: '5-11 yrs',
                    isAccessEnded: false,
                    screeningSessions: screenings,
                    practiceItems: practices,
                    goalItems: goalList,
                    rawObservations: obsList,
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Export Summary PDF'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Screening History (${summary.screeningSessions.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (summary.screeningSessions.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No screening sessions recorded yet.')))
        else
          ...summary.screeningSessions.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Risk Level: ${s['risk_level']?.toString().toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(s['created_at']?.toString().split('T').first ?? ''),
                        ],
                      ),
                      if (s['instrument_status'] != 'published') ...[
                        const SizedBox(height: 8),
                        const Chip(label: Text('Prototype - not clinically validated')),
                      ],
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 24),
        Text('Activity Practice Sessions (${summary.activitySessions.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (summary.activitySessions.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No activity sessions recorded yet.')))
        else
          ...summary.activitySessions.map((a) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('Domain: ${a['domain']?.toString().toUpperCase()}'),
                  subtitle: Text('Date: ${a['date']} • Duration: ${(a['duration_s'] ?? 0) ~/ 60} mins'),
                  trailing: Chip(label: Text('Support: ${a['support_level'] ?? 'independent'}')),
                ),
              )),
        if (showNotes) ...[
          const SizedBox(height: 24),
          Text('Observations (${observations.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (observations.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No observations shared.')))
          else
            ...observations.map((o) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o['note']?.toString() ?? '', style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 8),
                        Text('Setting: ${o['setting'] ?? 'General'} • Date: ${o['created_at']?.toString().split('T').first ?? ''}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 24),
          Text('Goals (${goals.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (goals.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No goals shared.')))
          else
            ...goals.map((g) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g['description']?.toString() ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Domain: ${g['domain']?.toString().toUpperCase()} • Status: ${g['status']} • Progress: ${g['progress']}%', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                )),
        ],
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Leave Link'),
                content: const Text('Are you sure you want to leave and remove access to this summary?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Leave'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              final repo = ref.read(sharingRepositoryProvider);
              await repo.revokeLink(linkId);
              ref.invalidate(myLinksProvider);
              if (!context.mounted) return;
              context.pop();
            }
          },
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Leave Link / Remove Access'),
        ),
      ],
    );
  }
}
