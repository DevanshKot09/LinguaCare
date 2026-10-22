import 'package:flutter/material.dart';
import 'export_action_widget.dart';

class ExportSummaryScreen extends StatelessWidget {
  const ExportSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Automatically trigger export dialog on load or display options
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showExportSummaryDialog(
        context: context,
        role: 'parent',
        scope: 'progress_notes',
        subjectNickname: 'Summary Subject',
        subjectAgeBand: '5-11 yrs',
        isAccessEnded: false,
        screeningSessions: const [],
        practiceItems: const [],
        goalItems: const [],
        rawObservations: const [],
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Export Summary')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf_rounded, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('Export Summary PDF', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Prepare and share your screening and practice summary securely.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  showExportSummaryDialog(
                    context: context,
                    role: 'parent',
                    scope: 'progress_notes',
                    subjectNickname: 'Summary Subject',
                    subjectAgeBand: '5-11 yrs',
                    isAccessEnded: false,
                    screeningSessions: const [],
                    practiceItems: const [],
                    goalItems: const [],
                    rawObservations: const [],
                  );
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('Open Export Dialog'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
