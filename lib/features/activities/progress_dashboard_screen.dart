import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/activities/activity_providers.dart';
import '../../domain/activities/progress_aggregator.dart';

class ProgressDashboardScreen extends ConsumerWidget {
  final String? childId;
  final String? subjectUid;
  final String title;

  const ProgressDashboardScreen({
    super.key,
    this.childId,
    this.subjectUid,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = childId != null
        ? ref.watch(progressForChildProvider(childId!))
        : subjectUid != null
            ? ref.watch(progressForSelfProvider(subjectUid!))
            : null;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: progressAsync == null
            ? const Center(child: Text('No progress data available.'))
            : progressAsync.when(
                data: (progress) => _buildDashboard(context, progress),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading progress: $e')),
              ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, ProgressSummary progress) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // Reassurance Note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Progress is not linear. Practice is about confidence and everyday communication, not clinical scores.',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Summary cards
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.sports_esports_rounded, color: Colors.teal),
                      const SizedBox(height: 8),
                      Text('${progress.totalSessions}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('Total Sessions', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.timer_rounded, color: Colors.amber),
                      const SizedBox(height: 8),
                      Text('${progress.totalMinutes}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('Total Minutes', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        const Text('Recent Trend & Observation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(progress.trendMessage, style: const TextStyle(fontSize: 15)),
          ),
        ),
        const SizedBox(height: 24),

        const Text('Domain Practice Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        if (progress.domainSummaries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No practice sessions recorded yet. Start an activity to track progress here.', textAlign: TextAlign.center),
            ),
          )
        else
          ...progress.domainSummaries.values.map((dom) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dom.domain.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Chip(label: Text('${dom.sessionCount} sessions')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Average Success: ${dom.averageSuccess.toStringAsFixed(1)} / 5'),
                      Text('Dominant Support: ${dom.dominantSupportLevel}'),
                      const SizedBox(height: 12),
                      // fl_chart bar chart snippet + Semantics accessibility table alternative
                      Semantics(
                        label: 'Bar chart showing average success for ${dom.domain}: ${dom.averageSuccess.toStringAsFixed(1)} out of 5',
                        child: SizedBox(
                          height: 100,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.center,
                              maxY: 5,
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: dom.averageSuccess,
                                      color: Colors.teal,
                                      width: 24,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ],
                                ),
                              ],
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            final q = childId != null ? 'childId=$childId' : 'subjectUid=$subjectUid';
            context.push('/screening/history?$q');
          },
          icon: const Icon(Icons.history_rounded),
          label: const Text('View Screening History'),
        ),
      ],
    );
  }
}
