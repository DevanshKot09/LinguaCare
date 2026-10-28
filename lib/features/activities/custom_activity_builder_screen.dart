import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomActivityBuilderScreen extends StatefulWidget {
  final String role; // 'parent' or 'teacher'

  const CustomActivityBuilderScreen({super.key, required this.role});

  @override
  State<CustomActivityBuilderScreen> createState() => _CustomActivityBuilderScreenState();
}

class CustomActivityModel {
  final String id;
  final String title;
  final String ageBand; // '5_11', '11_18', 'adult'
  final String category; // 'Vocabulary', 'Sentence Practice', 'Social Routine'
  final List<String> prompts;
  final DateTime createdAt;

  CustomActivityModel({
    required this.id,
    required this.title,
    required this.ageBand,
    required this.category,
    required this.prompts,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'ageBand': ageBand,
        'category': category,
        'prompts': prompts,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomActivityModel.fromJson(Map<String, dynamic> json) => CustomActivityModel(
        id: json['id'] as String,
        title: json['title'] as String,
        ageBand: json['ageBand'] as String? ?? '5_11',
        category: json['category'] as String? ?? 'Vocabulary',
        prompts: List<String>.from(json['prompts'] as List),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class _CustomActivityBuilderScreenState extends State<CustomActivityBuilderScreen> {
  static const String _storageKey = 'custom_user_activities_v1';
  List<CustomActivityModel> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_storageKey) ?? [];
    final loaded = <CustomActivityModel>[];
    for (final str in list) {
      try {
        loaded.add(CustomActivityModel.fromJson(json.decode(str)));
      } catch (_) {}
    }
    setState(() {
      _activities = loaded;
      _isLoading = false;
    });
  }

  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _activities.map((a) => json.encode(a.toJson())).toList();
    await prefs.setStringList(_storageKey, list);
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final promptCtrl = TextEditingController();
    final promptsList = <String>[];
    String selectedBand = '5_11';
    String selectedCategory = 'Vocabulary';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create Custom Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Activity Title',
                      hintText: 'e.g. Grandma\'s Garden Vocabulary',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedBand,
                          decoration: InputDecoration(
                            labelText: 'Age Band',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: '5_11', child: Text('5–11 Years')),
                            DropdownMenuItem(value: '11_18', child: Text('11–18 Years')),
                            DropdownMenuItem(value: 'adult', child: Text('Adult (18+)')),
                          ],
                          onChanged: (v) => setSheetState(() => selectedBand = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Vocabulary', child: Text('Vocabulary')),
                            DropdownMenuItem(value: 'Sentence Practice', child: Text('Sentence')),
                            DropdownMenuItem(value: 'Social Routine', child: Text('Social')),
                          ],
                          onChanged: (v) => setSheetState(() => selectedCategory = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add Practice Words / Questions:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: promptCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. Sunflower, Tomato, Watering can',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              setSheetState(() {
                                promptsList.add(val.trim());
                                promptCtrl.clear();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (promptCtrl.text.trim().isNotEmpty) {
                            setSheetState(() {
                              promptsList.add(promptCtrl.text.trim());
                              promptCtrl.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: promptsList.map((p) {
                      return Chip(
                        label: Text(p),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => setSheetState(() => promptsList.remove(p)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      if (titleCtrl.text.trim().isEmpty || promptsList.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a title and at least one prompt word!')),
                        );
                        return;
                      }
                      final newAct = CustomActivityModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleCtrl.text.trim(),
                        ageBand: selectedBand,
                        category: selectedCategory,
                        prompts: promptsList,
                        createdAt: DateTime.now(),
                      );
                      setState(() {
                        _activities.insert(0, newAct);
                      });
                      _saveActivities();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B32E8), Color(0xFF7952FC)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF4321BD),
                            offset: Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Save & Create Activity',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Quicksand',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _deleteActivity(int index) {
    setState(() {
      _activities.removeAt(index);
    });
    _saveActivities();
  }

  void _launchCustomPractice(CustomActivityModel act) {
    showDialog(
      context: context,
      builder: (ctx) => _CustomPracticeRunnerDialog(activity: act),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FD),
      appBar: AppBar(
        title: const Text(
          'Custom Therapy Builder',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Quicksand'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF5B32E8),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Activity',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Quicksand'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B32E8).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            size: 54,
                            color: Color(0xFF5B32E8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Custom Activities Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Quicksand',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the button below to design custom word flashcards, classroom prompts, and targeted therapy questions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Activity'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final act = _activities[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5B32E8).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    act.category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5B32E8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    act.ageBand == '5_11'
                                        ? 'Ages 5–11'
                                        : act.ageBand == '11_18'
                                            ? 'Ages 11–18'
                                            : 'Adult',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteActivity(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              act.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Quicksand',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${act.prompts.length} custom prompts: ${act.prompts.join(', ')}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _launchCustomPractice(act),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Start Practice Session'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5B32E8),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _CustomPracticeRunnerDialog extends StatefulWidget {
  final CustomActivityModel activity;

  const _CustomPracticeRunnerDialog({required this.activity});

  @override
  State<_CustomPracticeRunnerDialog> createState() => _CustomPracticeRunnerDialogState();
}

class _CustomPracticeRunnerDialogState extends State<_CustomPracticeRunnerDialog> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final prompts = widget.activity.prompts;
    final currentPrompt = prompts[_idx];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card ${_idx + 1} of ${prompts.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B32E8), Color(0xFF7952FC)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF4321BD),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  currentPrompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Quicksand',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (_idx > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _idx--),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_idx > 0) const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_idx < prompts.length - 1) {
                        setState(() => _idx++);
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Custom practice completed! Great job! ⭐')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C4B4),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_idx < prompts.length - 1 ? 'Next Word' : 'Finish ⭐'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
