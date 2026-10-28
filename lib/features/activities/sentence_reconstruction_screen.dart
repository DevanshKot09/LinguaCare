import 'package:flutter/material.dart';
import '../../domain/activities/activity.dart';
import 'activity_wrap_up_screen.dart';

class SentenceReconstructionScreen extends StatefulWidget {
  final String? studentName;
  final String? childId;
  final String? subjectUid;

  const SentenceReconstructionScreen({
    super.key,
    this.studentName,
    this.childId,
    this.subjectUid,
  });

  @override
  State<SentenceReconstructionScreen> createState() => _SentenceReconstructionScreenState();
}

class _ReconstructionItem {
  final String prompt;
  final List<String> correctWords;
  final List<String> scrambledWords;
  final String tip;

  const _ReconstructionItem({
    required this.prompt,
    required this.correctWords,
    required this.scrambledWords,
    required this.tip,
  });
}

class _SentenceReconstructionScreenState extends State<SentenceReconstructionScreen> {
  static const List<_ReconstructionItem> _items = [
    _ReconstructionItem(
      prompt: 'Build a complex sentence showing contrast:',
      correctWords: ['Although', 'the', 'project', 'was', 'hard,', 'Maya', 'explained', 'her', 'ideas', 'clearly.'],
      scrambledWords: ['explained', 'hard,', 'the', 'Maya', 'clearly.', 'project', 'Although', 'was', 'her', 'ideas'],
      tip: 'Start with the subordinating conjunction "Although" to link the contrasting clause.',
    ),
    _ReconstructionItem(
      prompt: 'Construct a collaborative classroom strategy:',
      correctWords: ['When', 'working', 'in', 'pairs,', 'we', 'listen', 'patiently', 'before', 'speaking.'],
      scrambledWords: ['listen', 'pairs,', 'When', 'speaking.', 'in', 'patiently', 'working', 'we', 'before'],
      tip: 'Time-connectors like "When" set the stage for polite classroom turn-taking.',
    ),
    _ReconstructionItem(
      prompt: 'Express a polite presentation request:',
      correctWords: ['Could', 'you', 'please', 'repeat', 'the', 'summary', 'one', 'more', 'time?'],
      scrambledWords: ['repeat', 'Could', 'time?', 'please', 'the', 'you', 'one', 'more', 'summary'],
      tip: 'Modal verbs like "Could" are excellent for advocating for clarification.',
    ),
  ];

  int _currentIndex = 0;
  late List<String> _remainingPool;
  final List<String> _assembledWords = [];
  bool? _isCorrect;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentItem();
  }

  void _loadCurrentItem() {
    _assembledWords.clear();
    _isCorrect = null;
    _feedbackMessage = null;
    _remainingPool = List<String>.from(_items[_currentIndex].scrambledWords);
  }

  void _addWord(String word) {
    setState(() {
      _remainingPool.remove(word);
      _assembledWords.add(word);
      _isCorrect = null;
      _feedbackMessage = null;
    });
  }

  void _removeWord(int index) {
    setState(() {
      final word = _assembledWords.removeAt(index);
      _remainingPool.add(word);
      _isCorrect = null;
      _feedbackMessage = null;
    });
  }

  void _checkSentence() {
    final item = _items[_currentIndex];
    final isMatch = _assembledWords.length == item.correctWords.length &&
        List.generate(_assembledWords.length, (i) => _assembledWords[i] == item.correctWords[i]).every((b) => b);

    setState(() {
      _isCorrect = isMatch;
      if (isMatch) {
        _feedbackMessage = 'Spot on! Grammatically and syntactically cohesive! ⭐';
      } else {
        _feedbackMessage = 'Not quite in sequence yet. Check the clause flow and try again!';
      }
    });
  }

  void _next() {
    if (_currentIndex < _items.length - 1) {
      setState(() {
        _currentIndex++;
        _loadCurrentItem();
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Masterful Construction! 🎯', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Quicksand')),
        content: const Text(
          'You successfully completed all sentence reconstruction challenges! Great job mastering complex language structure.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Practice'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C4B4),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              final activity = Activity(
                id: 'game_sentence_reconstruction',
                version: 1,
                status: 'published',
                title: 'Sentence Reconstruction',
                domain: 'grammar',
                type: 'sentence_building',
                ageBand: '11_18',
                audience: 'parent',
                estMinutes: 8,
                difficulty: 3,
                goal: 'Unscramble complex clauses and master syntax flow.',
                steps: const ['Reorder word tiles into grammatically correct sentences.'],
                parentTips: const ['Discuss connectives like although, because, and however.'],
                content: const {},
                visualSupport: true,
                strengthsMessage: 'Super syntax and grammar mastery!',
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ActivityWrapUpScreen(
                    activity: activity,
                    durationS: 120,
                    childId: widget.childId,
                    subjectUid: widget.subjectUid,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.star_rounded, color: Colors.amber),
            label: const Text('Claim Stars & Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_currentIndex];
    final title = widget.studentName != null ? '${widget.studentName}\'s Challenge' : 'Sentence Puzzle';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FD),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Quicksand'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Challenge ${_currentIndex + 1} of ${_items.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B32E8),
                      fontFamily: 'Quicksand',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _loadCurrentItem,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Prompt Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B32E8).withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.prompt,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Quicksand',
                        color: Color(0xFF1E1546),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '💡 Tip: ${item.tip}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Active Assembly Zone
              Container(
                constraints: const BoxConstraints(minHeight: 110),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isCorrect == true
                      ? const Color(0xFFE8F5E9)
                      : _isCorrect == false
                          ? const Color(0xFFFFEBEE)
                          : Colors.purple.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isCorrect == true
                        ? const Color(0xFF4CAF50)
                        : _isCorrect == false
                            ? const Color(0xFFFF5252)
                            : const Color(0xFF5B32E8).withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: _assembledWords.isEmpty
                    ? Center(
                        child: Text(
                          'Tap words below in order to build your sentence',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_assembledWords.length, (index) {
                          final word = _assembledWords[index];
                          return GestureDetector(
                            onTap: () => _removeWord(index),
                            child: Chip(
                              label: Text(
                                word,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5B32E8),
                                ),
                              ),
                              backgroundColor: Colors.white,
                              deleteIcon: const Icon(Icons.close_rounded, size: 14),
                              onDeleted: () => _removeWord(index),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Color(0xFF5B32E8)),
                              ),
                            ),
                          );
                        }),
                      ),
              ),
              const SizedBox(height: 16),

              // Feedback banner
              if (_feedbackMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _isCorrect == true ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isCorrect == true ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                    ),
                  ),
                  child: Text(
                    _feedbackMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _isCorrect == true ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    ),
                  ),
                ),

              // Word Pool
              const Text(
                'Available Word Tiles:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _remainingPool.map((word) {
                      return GestureDetector(
                        onTap: () => _addWord(word),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF5B32E8).withValues(alpha: 0.25),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFE0D7FA),
                                offset: Offset(0, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            word,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1546),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Action Buttons
              if (_isCorrect == true)
                GestureDetector(
                  onTap: _next,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C4B4), Color(0xFF009688)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF00796B),
                          offset: Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _currentIndex < _items.length - 1 ? 'Next Challenge →' : 'Complete Challenge 🎉',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: _assembledWords.isEmpty ? null : _checkSentence,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _assembledWords.isEmpty
                            ? [Colors.grey.shade400, Colors.grey.shade500]
                            : [const Color(0xFF5B32E8), const Color(0xFF7952FC)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _assembledWords.isEmpty ? Colors.grey.shade600 : const Color(0xFF4321BD),
                          offset: const Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Check Sentence',
                        style: TextStyle(
                          fontSize: 16,
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
      ),
    );
  }
}
