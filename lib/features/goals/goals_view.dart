import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/goals/goal.dart';

class GoalsView extends ConsumerStatefulWidget {
  final String childId;
  const GoalsView({super.key, required this.childId});

  @override
  ConsumerState<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends ConsumerState<GoalsView> {
  final _descController = TextEditingController();
  String _domain = 'vocabulary';
  int _progress = 0;

  Future<void> _addGoal() async {
    final desc = _descController.text.trim();
    if (desc.isEmpty) return;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final goal = Goal(
      childId: widget.childId,
      authorUid: userId,
      domain: _domain,
      description: desc,
      status: 'active',
      progress: _progress,
      createdAt: DateTime.now(),
    );

    final repo = ref.read(goalRepositoryProvider);
    await repo.addGoal(goal);
    _descController.clear();
    setState(() => _progress = 0);
    ref.invalidate(goalsProvider(widget.childId));
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add Communication Goal'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Domain', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    initialValue: _domain,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'vocabulary', child: Text('Vocabulary')),
                      DropdownMenuItem(value: 'understanding', child: Text('Understanding')),
                      DropdownMenuItem(value: 'grammar', child: Text('Grammar')),
                      DropdownMenuItem(value: 'narrative', child: Text('Narrative')),
                      DropdownMenuItem(value: 'conversation', child: Text('Conversation')),
                    ],
                    onChanged: (v) => setStateDialog(() => _domain = v ?? 'vocabulary'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Goal Description', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Text('Progress: $_progress%'),
                  Slider(
                    value: _progress.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '$_progress%',
                    onChanged: (v) => setStateDialog(() => _progress = v.toInt()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: _addGoal, child: const Text('Save Goal')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider(widget.childId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Communication Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Goal'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        goalsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return const Card(
                child: Padding(padding: EdgeInsets.all(24), child: Text('No goals set yet.', textAlign: TextAlign.center)),
              );
            }
            return Column(
              children: list.map((g) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(label: Text(g.domain.toUpperCase())),
                              Text('${g.progress}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(g.description, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: g.progress / 100.0),
                        ],
                      ),
                    ),
                  )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading goals: $e'),
        ),
      ],
    );
  }
}
