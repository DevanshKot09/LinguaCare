import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/screening/instrument.dart';
import '../../domain/screening/screening_providers.dart';
import '../../domain/screening/screening_result.dart';
import '../../l10n/app_localizations.dart';
import 'services/clinical_referral_pdf_service.dart';
import 'widgets/milestone_breakdown_matrix.dart';
import 'widgets/screening_domain_chart.dart';

class ScreeningReportScreen extends ConsumerWidget {
  final String instrumentId;
  final String? childId;

  const ScreeningReportScreen({
    super.key,
    required this.instrumentId,
    this.childId,
  });

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
        title: Text(
          l10n.reportTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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

    // Risk wording lookup
    String riskTitle = instrument.wording[result.riskLevel] ?? 'Screening result';
    Color riskColor = Colors.green;
    IconData riskIcon = Icons.check_circle_outline;

    switch (result.riskLevel) {
      case 'low':
        riskColor = const Color(0xFF10B981);
        riskIcon = Icons.check_circle;
        break;
      case 'some_signs':
        riskColor = const Color(0xFFF59E0B);
        riskIcon = Icons.info_outline;
        break;
      case 'high':
        riskColor = const Color(0xFFEF4444);
        riskIcon = Icons.warning_amber_rounded;
        break;
      default:
        riskColor = Colors.grey.shade700;
        riskIcon = Icons.help_outline;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      children: [
        if (result.instrumentStatus != 'published')
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade400),
            ),
            child: Row(
              children: [
                Icon(Icons.science_rounded, color: Colors.amber.shade900),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.prototypeBanner,
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
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
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.urgentNoticeTitle,
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.urgentNoticeMessage,
                  style: const TextStyle(color: Color(0xFFB91C1C), height: 1.35, fontSize: 13),
                ),
              ],
            ),
          ),

        // Risk Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: riskColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: riskColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: riskColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(riskIcon, color: riskColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          riskTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: riskColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: ${result.confidence.toUpperCase()} • ${(result.completeness * 100).toInt()}% completed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Visual Domain Chart using fl_chart
        ScreeningDomainChart(instrument: instrument, result: result),
        const SizedBox(height: 24),

        // Clinical Milestone Matrix
        MilestoneBreakdownMatrix(instrument: instrument, result: result),
        const SizedBox(height: 24),

        // Also Check With Professional
        if (result.alsoCheck.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 20, color: Color(0xFF5B32E8)),
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
                    child: Text('• ${l10n.hearingCheckAlways}', style: const TextStyle(fontSize: 13)),
                  ),
                ...result.alsoCheck
                    .where((tag) => tag != 'hearing')
                    .map((tag) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• Recommended assessment: ${tag.replaceAll('_', ' ')}', style: const TextStyle(fontSize: 13)),
                        )),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Clinical Referral & Action Suite
        Text(
          'Clinical Actions & Referral',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // Export PDF Button
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF371B99),
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              ClinicalReferralPdfService.generateAndPrintReferral(
                context: context,
                instrument: instrument,
                result: result,
              );
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
            label: const Text('Export Clinical Referral Document (PDF)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B32E8),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),

        // Copy Text Summary Button
        OutlinedButton.icon(
          onPressed: () {
            final summary = ClinicalReferralPdfService.generateTextSummary(
              instrument: instrument,
              result: result,
            );
            Clipboard.setData(ClipboardData(text: summary));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Clinical summary copied to clipboard! Ready to share.'),
                duration: Duration(seconds: 3),
              ),
            );
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copy Referral Summary to Clipboard'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 14),

        // Next Step List Tiles
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5B32E8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.people_rounded, color: Color(0xFF5B32E8)),
          ),
          title: const Text('Find & Consult Verified Specialist', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Connect with certified SLPs and book a tailored support plan'),
          trailing: const Icon(Icons.chevron_right),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          onTap: () => context.push('/specialist-directory'),
        ),
        const SizedBox(height: 8),

        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_outlined, color: Color(0xFF2563EB)),
          ),
          title: Text(l10n.learnMoreLink, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Access speech tools, visual schedules & simplifiers'),
          trailing: const Icon(Icons.chevron_right),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          onTap: () => context.go('/tools'),
        ),
        const SizedBox(height: 8),

        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.videogame_asset_outlined, color: Colors.green),
          ),
          title: const Text('Practice in Game Zone & Therapy Builder', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Custom word flashcards & age-adaptive speech games'),
          trailing: const Icon(Icons.chevron_right),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          onTap: () => context.go('/activities'),
        ),

        const SizedBox(height: 28),
        // Mandatory Non-Diagnostic Notice
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(14),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          child: Text(
            l10n.nonDiagnosticNotice,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
