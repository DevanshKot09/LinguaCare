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

  void _simplify() {
    final text = _controller.text;
    setState(() {
      _simplifiedSteps = InstructionSimplifier.simplify(text);
    });
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
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Original Instructions',
                hintText: 'Enter multi-step instructions here...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _simplify(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _simplify,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Simplify Instructions'),
            ),
            const SizedBox(height: 24),
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
              OutlinedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('Copy Simplified Steps'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
