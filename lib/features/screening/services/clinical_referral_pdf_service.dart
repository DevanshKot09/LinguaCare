import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:linguacare/domain/screening/instrument.dart';
import 'package:linguacare/domain/screening/screening_result.dart';
import '../data/screening_milestone_data.dart';

class ClinicalReferralPdfService {
  /// Generate and print or export the PDF report via system print / share sheet
  static Future<void> generateAndPrintReferral({
    required BuildContext context,
    required Instrument instrument,
    required ScreeningResult result,
    String? childName,
  }) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('MMMM d, yyyy');
    final formattedDate = dateFormat.format(result.createdAt);
    final subjectTitle = childName != null && childName.isNotEmpty
        ? childName
        : 'Child (${instrument.ageBand.replaceAll('_', '–')} years)';

    // Risk label formatting
    String riskLabel = result.riskLevel.toUpperCase();
    PdfColor riskColor = PdfColors.green800;
    if (result.riskLevel == 'some_signs') {
      riskLabel = 'SOME SIGNS NOTED';
      riskColor = PdfColors.orange800;
    } else if (result.riskLevel == 'high') {
      riskLabel = 'HIGH RISK / SEVERAL SIGNS';
      riskColor = PdfColors.red800;
    } else if (result.riskLevel == 'low') {
      riskLabel = 'LOW RISK / TYPICAL RANGE';
      riskColor = PdfColors.green800;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context pdfContext) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LinguaCare',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF5B32E8),
                      ),
                    ),
                    pw.Text(
                      'AI-Powered Early Language Screening & Clinical Support',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'CLINICAL REFERRAL BRIEFING',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                    ),
                    pw.Text('Date: $formattedDate', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.Text('Instrument: ${instrument.id} (v${instrument.version})', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            // Subject & Screening Summary Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Subject: $subjectTitle', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Text('Age Band: ${instrument.ageBand.replaceAll('_', '–')} Years', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Respondent: ${result.respondentRole.toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: riskColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(
                      riskLabel,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Urgent alerts if any
            if (result.urgent) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.red300),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('URGENT CLINICAL FLAG: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red900, fontSize: 10)),
                    pw.Expanded(
                      child: pw.Text(
                        'Audiological / hearing check or medical review strongly recommended before formal language evaluation.',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.red900),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
            ],

            // Domain Breakdown Table
            pw.Text(
              'Clinical Domain Breakdown & Benchmark Comparison',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Domain', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Observed Level', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Score', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Target Milestone Expectation', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                  ],
                ),
                ...instrument.domains.map((domain) {
                  final level = result.domainLevels[domain.id] ?? 'pending';
                  final score = (result.domainScores[domain.id] ?? 0.0).toInt();
                  final milestone = ScreeningMilestoneData.getMilestone(domain.id, instrument.ageBand);

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(domain.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(level.replaceAll('_', ' ').toUpperCase(), style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('$score%', style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(milestone.expectedMilestone, style: const pw.TextStyle(fontSize: 8)),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),

            // Recommended questions for SLP evaluation
            pw.Text(
              'Recommended Questions for Speech-Language Pathologist (SLP)',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
            ),
            pw.SizedBox(height: 6),
            pw.Bullet(text: 'Does the child show expressive vs receptive language discrepancy on standardized assessment?'),
            pw.Bullet(text: 'Are grammatical morphology errors (e.g. tense markers, pronouns) consistent with DLD profiles?'),
            pw.Bullet(text: 'Are word-finding delays attributable to semantic storage or phonological retrieval limitations?'),
            pw.Bullet(text: 'What visual supports, recasting cues, or classroom accommodations are indicated?'),
            pw.SizedBox(height: 16),

            // Non-Diagnostic Disclaimer
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Text(
                'IMPORTANT NON-DIAGNOSTIC NOTICE: LinguaCare is an AI-powered early developmental screening tool designed to identify children who may benefit from professional speech-language assessment. It does NOT provide a medical or clinical diagnosis. Formal diagnosis of Developmental Language Disorder (DLD) requires comprehensive evaluation by a qualified Speech-Language Pathologist (SLP) or clinical professional.',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'LinguaCare_Clinical_Referral_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Generate plain text summary for easy clipboard sharing
  static String generateTextSummary({
    required Instrument instrument,
    required ScreeningResult result,
    String? childName,
  }) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('MMMM d, yyyy');
    final formattedDate = dateFormat.format(result.createdAt);
    final subjectTitle = childName ?? 'Child (${instrument.ageBand.replaceAll('_', '–')} years)';

    buffer.writeln('📋 LINGUACARE CLINICAL LANGUAGE SCREENING SUMMARY');
    buffer.writeln('Date: $formattedDate');
    buffer.writeln('Subject: $subjectTitle');
    buffer.writeln('Age Band: ${instrument.ageBand.replaceAll('_', '–')} Years');
    buffer.writeln('Overall Screening Status: ${result.riskLevel.toUpperCase().replaceAll('_', ' ')}');
    buffer.writeln('Confidence: ${result.confidence.toUpperCase()} (${(result.completeness * 100).toInt()}% completed)');
    buffer.writeln('');

    if (result.urgent) {
      buffer.writeln('⚠️ URGENT CLINICAL NOTICE: Hearing check / audiology review recommended.');
      buffer.writeln('');
    }

    buffer.writeln('--- DOMAIN BREAKDOWN ---');
    for (final domain in instrument.domains) {
      final level = result.domainLevels[domain.id] ?? 'pending';
      final score = (result.domainScores[domain.id] ?? 0.0).toInt();
      final milestone = ScreeningMilestoneData.getMilestone(domain.id, instrument.ageBand);
      buffer.writeln('• ${domain.name}: $score% (${level.replaceAll('_', ' ').toUpperCase()})');
      buffer.writeln('  Milestone: ${milestone.expectedMilestone}');
      buffer.writeln('  Tip: ${milestone.recommendation}');
    }

    buffer.writeln('');
    buffer.writeln('--- RECOMMENDED NEXT STEPS ---');
    buffer.writeln('1. Consult a qualified Speech-Language Pathologist (SLP) for formal diagnostic assessment.');
    buffer.writeln('2. Rule out hearing/audiological concerns.');
    buffer.writeln('3. Implement responsive conversational scaffolding (recasting, chunking instructions).');
    buffer.writeln('');
    buffer.writeln('Notice: LinguaCare is a screening tool, not a diagnostic instrument. Diagnosis of DLD requires clinical evaluation by an SLP.');

    return buffer.toString();
  }
}
