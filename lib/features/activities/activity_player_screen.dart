import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/activities/activity.dart';
import 'activity_wrap_up_screen.dart';

class ActivityPlayerScreen extends ConsumerStatefulWidget {
  final Activity activity;
  final String? childId;
  final String? subjectUid;

  const ActivityPlayerScreen({
    super.key,
    required this.activity,
    this.childId,
    this.subjectUid,
  });

  @override
  ConsumerState<ActivityPlayerScreen> createState() => _ActivityPlayerScreenState();
}

class _ActivityPlayerScreenState extends ConsumerState<ActivityPlayerScreen> {
  late final DateTime _startTime;
  int _currentStepIndex = 0;
  bool _taskCompleted = false;

  // Type specific state
  // 1. Picture Word Match
  String? _selectedMatch;
  bool _matchCorrect = false;

  // 2. Follow Steps
  final List<String> _tappedSteps = [];

  // 3. Story Sequence
  late List<Map<String, dynamic>> _shuffledCards;

  // 4. Sentence Builder
  late List<String> _arrangedWords;

  // 5. Scenario Choice
  int? _selectedScenarioOption;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initTypeState();
  }

  void _initTypeState() {
    if (widget.activity.type == 'story_sequence') {
      final cards = (widget.activity.content['cards'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      cards.shuffle();
      _shuffledCards = cards;
    } else if (widget.activity.type == 'sentence_builder') {
      final words = (widget.activity.content['scrambled_words'] as List?)?.map((e) => e.toString()).toList() ?? [];
      words.shuffle();
      _arrangedWords = words;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChildView = widget.activity.ageBand == '5_11';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmExit(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.activity.title),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _confirmExit(context),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text('Step ${_currentStepIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress dots (not a score)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index <= _currentStepIndex ? Theme.of(context).colorScheme.primary : Colors.grey[350]!,
                        ),
                      )),
                ),
                const SizedBox(height: 24),

                // Main Content by Activity Type
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: _buildActivityWidget(context, isChildView),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Bottom control actions: Show me again / Skip / Next
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _showMeAgain,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Show me again'),
                    ),
                    TextButton(
                      onPressed: _skipTask,
                      child: const Text('Skip (No penalty)'),
                    ),
                    ElevatedButton(
                      onPressed: _canProceed() ? _nextStep : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canProceed() {
    if (_taskCompleted) return true;
    switch (widget.activity.type) {
      case 'picture_word_match':
        return _matchCorrect;
      case 'follow_steps':
        return _tappedSteps.length >= 2;
      case 'story_sequence':
        return true;
      case 'sentence_builder':
        return true;
      case 'scenario_choice':
        return _selectedScenarioOption != null;
      default:
        return true;
    }
  }

  Widget _buildActivityWidget(BuildContext context, bool isChildView) {
    switch (widget.activity.type) {
      case 'picture_word_match':
        return _buildPictureWordMatch(context);
      case 'follow_steps':
        return _buildFollowSteps(context);
      case 'story_sequence':
        return _buildStorySequence(context);
      case 'sentence_builder':
        return _buildSentenceBuilder(context);
      case 'scenario_choice':
        return _buildScenarioChoice(context);
      default:
        return Text(widget.activity.goal);
    }
  }

  Widget _buildPictureWordMatch(BuildContext context) {
    final content = widget.activity.content;
    final word = content['word'] as String? ?? '';
    final prompt = content['prompt'] as String? ?? '';
    final options = (content['options'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];

    return Column(
      children: [
        Text(prompt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(word, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: options.map((opt) {
            final label = opt['label'] as String? ?? '';
            final icon = opt['icon'] as String? ?? '';
            final isCorrect = opt['is_correct'] as bool? ?? false;
            final isSelected = _selectedMatch == label;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedMatch = label;
                  _matchCorrect = isCorrect;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isSelected ? (isCorrect ? Colors.green.shade100 : Colors.red.shade100) : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? (isCorrect ? Colors.green : Colors.red) : Colors.transparent, width: 3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_matchCorrect) ...[
          const SizedBox(height: 16),
          Text(widget.activity.strengthsMessage, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ],
    );
  }

  Widget _buildFollowSteps(BuildContext context) {
    final content = widget.activity.content;
    final availableItems = (content['available_items'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];

    return Column(
      children: [
        const Text('Follow the instructions in order:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...((content['instruction_steps'] as List?) ?? []).map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('• ${step['prompt']}', style: const TextStyle(fontSize: 16)),
            )),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: availableItems.map((item) {
            final id = item['id'] as String? ?? '';
            final label = item['label'] as String? ?? '';
            final icon = item['icon'] as String? ?? '';
            final tappedIndex = _tappedSteps.indexOf(id);

            return InkWell(
              onTap: () {
                setState(() {
                  if (!_tappedSteps.contains(id)) {
                    _tappedSteps.add(id);
                  }
                });
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: tappedIndex != -1 ? Colors.blue.shade100 : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tappedIndex != -1 ? Colors.blue : Colors.transparent, width: 3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (tappedIndex != -1) Text('#${tappedIndex + 1}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStorySequence(BuildContext context) {
    return Column(
      children: [
        const Text('Reorder the story cards correctly:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ..._shuffledCards.map((card) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Text(card['icon'] as String? ?? '', style: const TextStyle(fontSize: 28)),
                title: Text(card['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded),
                      onPressed: () {
                        final index = _shuffledCards.indexOf(card);
                        if (index > 0) {
                          setState(() {
                            _shuffledCards.removeAt(index);
                            _shuffledCards.insert(index - 1, card);
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward_rounded),
                      onPressed: () {
                        final index = _shuffledCards.indexOf(card);
                        if (index < _shuffledCards.length - 1) {
                          setState(() {
                            _shuffledCards.removeAt(index);
                            _shuffledCards.insert(index + 1, card);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 12),
        Text(widget.activity.content['retell_prompt'] as String? ?? '', style: const TextStyle(fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildSentenceBuilder(BuildContext context) {
    return Column(
      children: [
        const Text('Arrange the words to build a sentence:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _arrangedWords.map((word) => Chip(
                label: Text(word, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                deleteIcon: const Icon(Icons.swap_horiz_rounded),
                onDeleted: () {
                  setState(() {
                    // Simple rotation
                    _arrangedWords.remove(word);
                    _arrangedWords.add(word);
                  });
                },
              )).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Tap chip to rotate order', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildScenarioChoice(BuildContext context) {
    final content = widget.activity.content;
    final scenario = content['scenario'] as String? ?? '';
    final options = (content['options'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(scenario, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...options.asMap().entries.map((entry) {
          final idx = entry.key;
          final opt = entry.value;
          final isSelected = _selectedScenarioOption == idx;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
            child: InkWell(
              onTap: () => setState(() => _selectedScenarioOption = idx),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt['text'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (isSelected) ...[
                      const SizedBox(height: 8),
                      Text(opt['explanation'] as String? ?? '', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showMeAgain() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guidance: Read instructions slowly and use visual cues.')),
    );
  }

  void _skipTask() {
    _nextStep();
  }

  void _nextStep() {
    if (_currentStepIndex < 1) {
      setState(() {
        _currentStepIndex++;
      });
    } else {
      setState(() {
        _taskCompleted = true;
      });
      // Proceed to wrap up screen
      final duration = DateTime.now().difference(_startTime).inSeconds;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ActivityWrapUpScreen(
            activity: widget.activity,
            durationS: duration,
            childId: widget.childId,
            subjectUid: widget.subjectUid,
          ),
        ),
      );
    }
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Activity?'),
        content: const Text('Your progress for this session will not be saved if you exit now.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continue Practice')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
    return confirmed ?? false;
  }
}
