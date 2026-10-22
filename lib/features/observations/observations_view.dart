import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/observations/observation.dart';

class ObservationsView extends ConsumerStatefulWidget {
  final String childId;
  const ObservationsView({super.key, required this.childId});

  @override
  ConsumerState<ObservationsView> createState() => _ObservationsViewState();
}

class _ObservationsViewState extends ConsumerState<ObservationsView> {
  final _noteController = TextEditingController();
  String _setting = 'Home';
  bool _private = false;
  String? _formError;

  final List<String> _settingsList = ['Home', 'Classroom', 'Clinic', 'Playground', 'Other'];

  bool _containsPhoneOrEmail(String text) {
    final phoneRegExp = RegExp(r'\d{3}[-.\s]?\d{3}[-.\s]?\d{4}');
    final emailRegExp = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
    return phoneRegExp.hasMatch(text) || emailRegExp.hasMatch(text);
  }

  Future<void> _addObservation() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      setState(() => _formError = 'Observation note cannot be empty.');
      return;
    }
    if (note.length > 500) {
      setState(() => _formError = 'Observation note exceeds 500 characters.');
      return;
    }
    if (_containsPhoneOrEmail(note)) {
      setState(() => _formError = 'Please avoid full names, addresses, phone numbers, or emails.');
      return;
    }

    setState(() => _formError = null);

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final obs = Observation(
      childId: widget.childId,
      authorUid: userId,
      tags: ['general'],
      note: note,
      setting: _setting,
      private: _private,
      createdAt: DateTime.now(),
    );

    try {
      final repo = ref.read(observationRepositoryProvider);
      await repo.addObservation(obs);
      _noteController.clear();
      setState(() => _private = false);
      ref.invalidate(observationsProvider(widget.childId));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _formError = 'Failed to save observation: $e');
    }
  }

  void _showAddDialog(BuildContext context) {
    setState(() => _formError = null);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add Observation'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_formError != null) ...[
                    Text(_formError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    const SizedBox(height: 8),
                  ],
                  const Text('Please avoid full names, addresses or phone numbers', style: TextStyle(fontSize: 12, color: Colors.blue, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Observation Note (max 500 chars)',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 16),
                  const Text('Setting', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    initialValue: _setting,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _settingsList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setStateDialog(() => _setting = v ?? 'Home'),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Private Note'),
                    subtitle: const Text('Visible only to you'),
                    value: _private,
                    onChanged: (v) => setStateDialog(() => _private = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: _addObservation, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final obsAsync = ref.watch(observationsProvider(widget.childId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Observations Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        obsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return const Card(
                child: Padding(padding: EdgeInsets.all(24), child: Text('No observations recorded yet.', textAlign: TextAlign.center)),
              );
            }
            return Column(
              children: list.map((o) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(o.note),
                      subtitle: Text('Setting: ${o.setting ?? 'Home'} • ${o.private ? '🔒 Private' : '🌐 Shared'} • ${o.createdAt.toLocal().toString().split('.').first}'),
                      isThreeLine: true,
                    ),
                  )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading observations: $e'),
        ),
      ],
    );
  }
}
