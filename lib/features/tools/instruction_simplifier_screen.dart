import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'instruction_simplifier.dart';

class InstructionSimplifierScreen extends StatefulWidget {
  const InstructionSimplifierScreen({super.key});

  @override
  State<InstructionSimplifierScreen> createState() => _InstructionSimplifierScreenState();
}

class _InstructionSimplifierScreenState extends State<InstructionSimplifierScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _simplifiedSteps = [];

  final List<Map<String, String>> _presetScenarios = const [
    {
      'label': 'Workplace Task',
      'icon': '💼',
      'text': 'Please make sure to finalize the quarterly expenditure summary before Friday afternoon, after you have verified the invoices with accounting, and then send an email copy to the department manager.',
    },
    {
      'label': "Doctor's Advice",
      'icon': '🩺',
      'text': 'Take two tablets twice daily after meals for five days, but make sure to drink plenty of water and stop taking them immediately if you feel dizzy.',
    },
    {
      'label': 'Official Procedure',
      'icon': '🏦',
      'text': 'Kindly bring two copies of your address proof and original photo ID to counter 3, and then wait for your token number to be announced on the screen.',
    },
  ];

  void _simplify() {
    final text = _controller.text;
    setState(() {
      _simplifiedSteps = InstructionSimplifier.simplify(text);
    });
  }

  void _applyPreset(String text) {
    _controller.text = text;
    _simplify();
  }

  void _copyToClipboard() {
    final buffer = StringBuffer();
    for (int i = 0; i < _simplifiedSteps.length; i++) {
      buffer.writeln('${i + 1}. ${_simplifiedSteps[i]}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied simplified instructions to clipboard.')),
    );
  }

  void _openStepByStepFocus() {
    if (_simplifiedSteps.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => _StepByStepFocusDialog(steps: _simplifiedSteps),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instruction Simplifier'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'A helper for preparing clear instructions; it does not lower expectations.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quick Scenarios (Tap to try):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presetScenarios.map((scenario) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      avatar: Text(scenario['icon']!, style: const TextStyle(fontSize: 14)),
                      label: Text(scenario['label']!),
                      onPressed: () => _applyPreset(scenario['text']!),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Original Instructions',
                hintText: 'Enter or paste multi-step directions here...',
                border: const OutlineInputBorder(),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _simplify();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _simplify(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _simplify,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Simplify Instructions'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Side-by-Side Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Original', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(_controller.text.isEmpty ? 'No input yet.' : _controller.text),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Simplified Steps', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (_simplifiedSteps.isEmpty)
                            const Text('Simplified steps will appear here.')
                          else
                            ..._simplifiedSteps.asMap().entries.map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Text('${entry.key + 1}. ${entry.value}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_simplifiedSteps.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: _openStepByStepFocus,
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: const Text('Step-by-Step Focus'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Steps'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepByStepFocusDialog extends StatefulWidget {
  final List<String> steps;

  const _StepByStepFocusDialog({required this.steps});

  @override
  State<_StepByStepFocusDialog> createState() => _StepByStepFocusDialogState();
}

class _StepByStepFocusDialogState extends State<_StepByStepFocusDialog> {
  int _currentStepIndex = 0;
  final Set<int> _completedSteps = {};

  @override
  Widget build(BuildContext context) {
    final stepText = widget.steps[_currentStepIndex];
    final isDone = _completedSteps.contains(_currentStepIndex);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Step ${_currentStepIndex + 1} of ${widget.steps.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(minHeight: 140),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDone
                    ? Colors.green.shade50
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDone ? Colors.green.shade300 : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Text(
                stepText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? Colors.green.shade900 : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  if (isDone) {
                    _completedSteps.remove(_currentStepIndex);
                  } else {
                    _completedSteps.add(_currentStepIndex);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: isDone ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDone ? 'Marked as Done' : 'Mark this step done',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDone ? Colors.green : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _currentStepIndex > 0
                      ? () => setState(() => _currentStepIndex--)
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
                ElevatedButton.icon(
                  onPressed: _currentStepIndex < widget.steps.length - 1
                      ? () => setState(() => _currentStepIndex++)
                      : () => Navigator.pop(context),
                  icon: Icon(_currentStepIndex < widget.steps.length - 1
                      ? Icons.arrow_forward
                      : Icons.done_all_rounded),
                  label: Text(_currentStepIndex < widget.steps.length - 1 ? 'Next' : 'Finish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
