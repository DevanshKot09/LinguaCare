import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/screening/instrument.dart';
import '../../domain/screening/screening_providers.dart';
import '../../domain/screening/screening_result.dart';
import '../../l10n/app_localizations.dart';

class ScreeningReportScreen extends ConsumerWidget {
  final String instrumentId;
  final String? childId;

  const ScreeningReportScreen({
    Key? key,
    required this.instrumentId,
    this.childId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final instrumentAsync = ref.watch(instrumentProvider(instrumentId));
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final historyAsync = childId != null
        ? ref.watch(childScreeningHistoryProvider(childId!))
        : ref.watch(selfScreeningHistoryProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(childId != null ? '/parent' : '/adult'),
          ),
        ],
      ),
      body: instrumentAsync.when(
        data: (instrument) {
          return historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return const Center(child: Text('No recent screening results found.'));
              }
              final result = history.first; // Latest result
              return _buildReportContent(context, ref, instrument, result);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading history: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading instrument: $err')),
      ),
    );
  }

  Widget _buildReportContent(
    BuildContext context,
    WidgetRef ref,
    Instrument instrument,
    ScreeningResult result,
  ) {
    final l10n = AppLocalizations.of(context)!;

    // Risk wording lookup from config
    String riskTitle = instrument.wording[result.riskLevel] ?? 'Screening result';
    Color riskColor = Colors.green;
    IconData riskIcon = Icons.check_circle_outline;

    switch (result.riskLevel) {
      case 'low':
        riskColor = Colors.green.shade700;
        riskIcon = Icons.check_circle;
        break;
      case 'some_signs':
        riskColor = Colors.orange.shade800;
        riskIcon = Icons.info_outline;
        break;
      case 'high':
        riskColor = Colors.red.shade700;
        riskIcon = Icons.warning_amber_rounded;
        break;
      default:
        riskColor = Colors.grey.shade700;
        riskIcon = Icons.help_outline;
    }

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        if (result.instrumentStatus != 'published')
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade700),
            ),
            child: Row(
              children: [
                Icon(Icons.science, color: Colors.amber.shade900),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.prototypeBanner,
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Urgent Notice if triggered
        if (result.urgent)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade300, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      l10n.urgentNoticeTitle,
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.urgentNoticeMessage,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ],
            ),
          ),

        // Risk Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: riskColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(riskIcon, color: riskColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      riskTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: riskColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Confidence: ${result.confidence.toUpperCase()} (${(result.completeness * 100).toInt()}% answered)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Strengths First Section
        Text(
          l10n.strengthsFirst,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ..._buildDomainCards(context, instrument, result, strengthsOnly: true),

        const SizedBox(height: 24),
        // Areas to Watch Section
        Text(
          l10n.areasToWatch,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ..._buildDomainCards(context, instrument, result, strengthsOnly: false),

        // Also Check With Professional
        if (result.alsoCheck.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.alsoCheckWithProfessional,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (result.alsoCheck.contains('hearing'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• ${l10n.hearingCheckAlways}'),
                  ),
                ...result.alsoCheck
                    .where((tag) => tag != 'hearing')
                    .map((tag) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• Recommended check: ${tag.replaceAll('_', ' ')}'),
                        )),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        // What You Can Do Next
        Text(
          l10n.whatYouCanDoNext,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.school_outlined),
          title: Text(l10n.learnMoreLink),
          trailing: const Icon(Icons.chevron_right),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          onTap: () => context.go('/learn'),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: Text(l10n.findSpecialistComingSoon),
          enabled: false,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.share_outlined),
          title: Text(l10n.shareWithTeacherComingSoon),
          enabled: false,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        ),

        const SizedBox(height: 32),
        // Mandatory Non-Diagnostic Notice
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.nonDiagnosticNotice,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDomainCards(
    BuildContext context,
    Instrument instrument,
    ScreeningResult result, {
    required bool strengthsOnly,
  }) {
    final widgets = <Widget>[];

    for (var domain in instrument.domains) {
      final level = result.domainLevels[domain.id] ?? 'insufficient_data';
      final isStrength = level == 'strength' || level == 'typical_range';

      if (strengthsOnly && !isStrength) continue;
      if (!strengthsOnly && isStrength) continue;

      String levelText = '';
      Color chipColor = Colors.grey;

      switch (level) {
        case 'strength':
          levelText = 'Thriving / Strength';
          chipColor = Colors.green;
          break;
        case 'typical_range':
          levelText = 'Typical Range';
          chipColor = Colors.blue;
          break;
        case 'some_signs':
          levelText = 'Some Signs';
          chipColor = Colors.orange;
          break;
        case 'more_signs':
          levelText = 'More Signs to Watch';
          chipColor = Colors.red;
          break;
        default:
          levelText = 'Not enough data';
          chipColor = Colors.grey;
      }

      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        domain.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status level based on responses.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: chipColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: chipColor),
                  ),
                  child: Text(
                    levelText,
                    style: TextStyle(
                      color: chipColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            strengthsOnly ? 'No particular domains noted as strengths yet.' : 'No domains flagged in this section.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return widgets;
  }
}
