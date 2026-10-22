import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tools_models.dart';
import '../../core/local_store/local_store.dart';
import '../../app/router/app_session.dart';
import 'uuid_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdultJournalScreen extends ConsumerStatefulWidget {
  const AdultJournalScreen({super.key});

  @override
  ConsumerState<AdultJournalScreen> createState() => _AdultJournalScreenState();
}

class _AdultJournalScreenState extends ConsumerState<AdultJournalScreen> {
  List<JournalEntry> _entries = [];
  bool _isLoading = true;
  bool _showChart = true;

  final List<Map<String, dynamic>> _moodOptions = [
    {'key': 'great', 'label': 'Great', 'icon': '🌟', 'score': 5},
    {'key': 'good', 'label': 'Good', 'icon': '😊', 'score': 4},
    {'key': 'okay', 'label': 'Okay', 'icon': '😐', 'score': 3},
    {'key': 'low', 'label': 'Low', 'icon': '🌧️', 'score': 2},
    {'key': 'overwhelmed', 'label': 'Overwhelmed', 'icon': '⚡', 'score': 1},
  ];

  final List<String> _situationTags = [
    'at work or school',
    'with friends',
    'on the phone',
    'shopping',
    'with family',
    'at an appointment',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final session = ref.read(appSessionStateProvider);
    final userId = session.user?.uid ?? 'guest';
    final store = LocalStore(userId);
    final list = await store.readList('adult_journal_entries', []);
    setState(() {
      _entries = list.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)).toList();
      _entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      _isLoading = false;
    });
  }

  Future<void> _saveEntries() async {
    final session = ref.read(appSessionStateProvider);
    final userId = session.user?.uid ?? 'guest';
    final store = LocalStore(userId);
    await store.writeList('adult_journal_entries', _entries.map((e) => e.toJson()).toList());
  }

  void _addOrEditEntry({JournalEntry? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _JournalEditorModal(
        existing: existing,
        moodOptions: _moodOptions,
        situationTags: _situationTags,
        onSave: (entry) {
          setState(() {
            if (existing != null) {
              final idx = _entries.indexWhere((e) => e.id == existing.id);
              if (idx != -1) _entries[idx] = entry;
            } else {
              _entries.insert(0, entry);
            }
          });
          _saveEntries();
        },
      ),
    );
  }

  void _deleteEntry(String id) {
    setState(() {
      _entries.removeWhere((e) => e.id == id);
    });
    _saveEntries();
  }

  Future<void> _clearJournal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Journal'),
        content: const Text('Are you sure you want to delete all journal entries on this device? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _entries.clear();
      });
      _saveEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Adult Wellbeing Journal')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adult Wellbeing Journal'),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear journal',
              onPressed: _clearJournal,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Notice: Data is stored locally on your device only and is never uploaded.',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                'If things feel heavy, consider talking with someone you trust or a professional.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _addOrEditEntry(),
              icon: const Icon(Icons.add),
              label: const Text('Add Journal Entry'),
            ),
            const SizedBox(height: 24),
            if (_entries.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Weekly Wellbeing Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ToggleButtons(
                    isSelected: [_showChart, !_showChart],
                    onPressed: (idx) => setState(() => _showChart = idx == 0),
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Chart')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Table')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummaryView(),
              const SizedBox(height: 24),
            ],
            const Text('Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_entries.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No journal entries yet.')))
            else
              ..._buildGroupedEntriesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryView() {
    if (_showChart) {
      return SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 5,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < _entries.take(7).length) {
                      final entry = _entries.take(7).toList()[value.toInt()];
                      return Text(DateFormat('M/d').format(entry.dateTime), style: const TextStyle(fontSize: 10));
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: _entries.take(7).toList().asMap().entries.map((e) {
              final moodOpt = _moodOptions.firstWhere((m) => m['key'] == e.value.mood, orElse: () => _moodOptions[2]);
              final score = (moodOpt['score'] as int).toDouble();
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(toY: score, color: Theme.of(context).colorScheme.primary, width: 16, borderRadius: BorderRadius.circular(4)),
                ],
              );
            }).toList(),
          ),
        ),
      );
    } else {
      // Text / Table alternative
      return Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth(), 2: FlexColumnWidth()},
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            children: [
              Padding(padding: EdgeInsets.all(8.0), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8.0), child: Text('Mood', style: TextStyle(fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8.0), child: Text('Situation', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          ..._entries.take(10).map((e) {
            final moodOpt = _moodOptions.firstWhere((m) => m['key'] == e.mood, orElse: () => _moodOptions[2]);
            return TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8.0), child: Text(DateFormat('MMM d').format(e.dateTime))),
                Padding(padding: const EdgeInsets.all(8.0), child: Text('${moodOpt['icon']} ${moodOpt['label']}')),
                Padding(padding: const EdgeInsets.all(8.0), child: Text(e.situationTags.join(', '))),
              ],
            );
          }),
        ],
      );
    }
  }

  List<Widget> _buildGroupedEntriesList() {
    return _entries.map((entry) {
      final moodOpt = _moodOptions.firstWhere((m) => m['key'] == entry.mood, orElse: () => _moodOptions[2]);
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(entry.dateTime),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _deleteEntry(entry.id),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(moodOpt['icon'] as String, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(moodOpt['label'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              if (entry.situationTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: entry.situationTags
                      .map((tag) => Chip(label: Text(tag, style: const TextStyle(fontSize: 12))))
                      .toList(),
                ),
              ],
              if (entry.note != null && entry.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(entry.note!, style: const TextStyle(fontSize: 14)),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _JournalEditorModal extends StatefulWidget {
  final JournalEntry? existing;
  final List<Map<String, dynamic>> moodOptions;
  final List<String> situationTags;
  final ValueChanged<JournalEntry> onSave;

  const _JournalEditorModal({
    this.existing,
    required this.moodOptions,
    required this.situationTags,
    required this.onSave,
  });

  @override
  State<_JournalEditorModal> createState() => _JournalEditorModalState();
}

class _JournalEditorModalState extends State<_JournalEditorModal> {
  late String _selectedMood;
  late List<String> _selectedTags;
  late TextEditingController _noteController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.existing?.mood ?? 'good';
    _selectedTags = List.from(widget.existing?.situationTags ?? []);
    _noteController = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool _containsPhoneOrEmail(String text) {
    final phoneRegExp = RegExp(r'\d{3}[-.\s]?\d{3}[-.\s]?\d{4}');
    final emailRegExp = RegExp(r'^[\w-]+@([\w-]+\.)+[\w-]{2,4}$');
    return phoneRegExp.hasMatch(text) || emailRegExp.hasMatch(text);
  }

  void _save() {
    final note = _noteController.text.trim();
    if (note.isNotEmpty) {
      if (_containsPhoneOrEmail(note)) {
        setState(() {
          _errorText = 'Please avoid full names, addresses, phone numbers, or emails.';
        });
        return;
      }
    }

    final entry = JournalEntry(
      id: widget.existing?.id ?? generateUuid(),
      dateIso: widget.existing?.dateIso ?? DateTime.now().toIso8601String(),
      mood: _selectedMood,
      situationTags: _selectedTags,
      note: note.isEmpty ? null : note,
    );
    widget.onSave(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Journal Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_errorText != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withValues(alpha: 0.1),
                child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 12),
            ],
            const Text('How are you feeling?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.moodOptions.map((mood) {
                final isSelected = _selectedMood == mood['key'];
                return ChoiceChip(
                  label: Text('${mood['icon']} ${mood['label']}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedMood = mood['key']);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Situation Tags', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: widget.situationTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Optional Note',
                hintText: 'Please avoid full names, addresses or phone numbers',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save Entry'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
