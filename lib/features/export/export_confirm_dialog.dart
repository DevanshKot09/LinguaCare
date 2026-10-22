import 'package:flutter/material.dart';

class ExportConfirmDialog extends StatefulWidget {
  final bool showNotesToggle;
  final ValueChanged<bool> onConfirmed;

  const ExportConfirmDialog({
    super.key,
    required this.showNotesToggle,
    required this.onConfirmed,
  });

  @override
  State<ExportConfirmDialog> createState() => _ExportConfirmDialogState();
}

class _ExportConfirmDialogState extends State<ExportConfirmDialog> {
  bool _includeNotes = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Summary PDF'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This PDF leaves the app. Anyone you send it to can read it. Share it only with people you trust.',
                      style: TextStyle(fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showNotesToggle) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Include notes'),
                subtitle: const Text('Include non-private observation notes in the summary'),
                value: _includeNotes,
                onChanged: _isLoading ? null : (val) => setState(() => _includeNotes = val),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    widget.onConfirmed(_includeNotes);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create PDF'),
        ),
      ],
    );
  }
}
