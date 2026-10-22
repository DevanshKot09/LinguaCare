import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tools_models.dart';
import '../../core/local_store/local_store.dart';
import '../../app/router/app_session.dart';
import 'uuid_helper.dart';

class CommunicationCardScreen extends ConsumerStatefulWidget {
  const CommunicationCardScreen({super.key});

  @override
  ConsumerState<CommunicationCardScreen> createState() => _CommunicationCardScreenState();
}

class _CommunicationCardScreenState extends ConsumerState<CommunicationCardScreen> {
  List<CommunicationCardModel> _cards = [];
  bool _isLoading = true;

  final List<String> _presetNeeds = [
    'I need extra time',
    'Please use shorter sentences',
    'Please write it down',
    'Please show me',
    'I may ask you to repeat',
    'Please check that I understood',
  ];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final session = ref.read(appSessionStateProvider);
    final userId = session.user?.uid ?? 'guest';
    final store = LocalStore(userId);
    final list = await store.readList('communication_cards', []);
    setState(() {
      _cards = list.map((e) => CommunicationCardModel.fromJson(e as Map<String, dynamic>)).toList();
      if (_cards.isEmpty) {
        _cards.add(CommunicationCardModel(
          id: generateUuid(),
          title: 'My Needs',
          needs: ['I need extra time', 'Please write it down'],
          customLines: ['Thank you for your patience.'],
        ));
      }
      _isLoading = false;
    });
  }

  Future<void> _saveCards() async {
    final session = ref.read(appSessionStateProvider);
    final userId = session.user?.uid ?? 'guest';
    final store = LocalStore(userId);
    await store.writeList('communication_cards', _cards.map((c) => c.toJson()).toList());
  }

  void _addCard() {
    if (_cards.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 communication cards allowed.')),
      );
      return;
    }

    final newCard = CommunicationCardModel(
      id: generateUuid(),
      title: 'Card ${_cards.length + 1}',
      needs: [_presetNeeds.first],
      customLines: [],
    );

    setState(() {
      _cards.add(newCard);
    });
    _saveCards();
  }

  void _deleteCard(String id) {
    setState(() {
      _cards.removeWhere((c) => c.id == id);
    });
    _saveCards();
  }

  void _openEditor(CommunicationCardModel card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CardEditorScreen(
          card: card,
          presetNeeds: _presetNeeds,
          onSave: (updated) {
            setState(() {
              final idx = _cards.indexWhere((c) => c.id == updated.id);
              if (idx != -1) {
                _cards[idx] = updated;
              }
            });
            _saveCards();
          },
        ),
      ),
    );
  }

  void _openFullScreen(CommunicationCardModel card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenCardView(card: card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Communication Cards')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Card',
            onPressed: _addCard,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _cards.length,
          itemBuilder: (context, index) {
            final card = _cards[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(card.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _openEditor(card),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => _deleteCard(card.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...card.needs.map((n) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(child: Text(n, style: const TextStyle(fontSize: 15))),
                            ],
                          ),
                        )),
                    ...card.customLines.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(c, style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
                        )),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade100,
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: () => _openFullScreen(card),
                      icon: const Icon(Icons.fullscreen),
                      label: const Text('Show High-Contrast Full Screen'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CardEditorScreen extends StatefulWidget {
  final CommunicationCardModel card;
  final List<String> presetNeeds;
  final ValueChanged<CommunicationCardModel> onSave;

  const _CardEditorScreen({
    required this.card,
    required this.presetNeeds,
    required this.onSave,
  });

  @override
  State<_CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<_CardEditorScreen> {
  late TextEditingController _titleController;
  late List<String> _selectedNeeds;
  late List<TextEditingController> _customControllers;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card.title);
    _selectedNeeds = List.from(widget.card.needs);
    _customControllers = widget.card.customLines
        .map((line) => TextEditingController(text: line))
        .toList();
    if (_customControllers.isEmpty) {
      _customControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final c in _customControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool _containsPhoneOrEmail(String text) {
    final phoneRegExp = RegExp(r'\d{3}[-.\s]?\d{3}[-.\s]?\d{4}');
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return phoneRegExp.hasMatch(text) || emailRegExp.hasMatch(text);
  }

  void _save() {
    final customLines = <String>[];
    for (final c in _customControllers) {
      final text = c.text.trim();
      if (text.isNotEmpty) {
        if (_containsPhoneOrEmail(text)) {
          setState(() {
            _errorText = 'Please avoid full names, addresses, phone numbers, or emails.';
          });
          return;
        }
        customLines.add(text);
      }
    }

    if (customLines.length > 2) {
      setState(() {
        _errorText = 'Maximum 2 custom lines allowed.';
      });
      return;
    }

    final updated = widget.card.copyWith(
      title: _titleController.text.trim().isEmpty ? 'Card' : _titleController.text.trim(),
      needs: _selectedNeeds,
      customLines: customLines,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Communication Card'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorText != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.withValues(alpha: 0.1),
                child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Card Title', border: OutlineInputBorder()),
              maxLength: 40,
            ),
            const SizedBox(height: 16),
            const Text('Select Needs (fixed list)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...widget.presetNeeds.map((need) {
              final isSelected = _selectedNeeds.contains(need);
              return CheckboxListTile(
                title: Text(need),
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedNeeds.add(need);
                    } else {
                      _selectedNeeds.remove(need);
                    }
                  });
                },
              );
            }),
            const Divider(height: 32),
            const Text('Custom Lines (up to 2)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Please avoid full names, addresses or phone numbers', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            ..._customControllers.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: 'Custom Line ${entry.key + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    maxLength: 80,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _FullScreenCardView extends StatelessWidget {
  final CommunicationCardModel card;

  const _FullScreenCardView({required this.card});

  void _copyCardText(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln(card.title);
    for (final n in card.needs) {
      buffer.writeln('• $n');
    }
    for (final c in card.customLines) {
      buffer.writeln(c);
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Card text copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade100,
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade200,
        title: Text(card.title, style: const TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy as text',
            onPressed: () => _copyCardText(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...card.needs.map((n) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        n,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    )),
                ...card.customLines.map((c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        c,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontStyle: FontStyle.italic, color: Colors.black87),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
