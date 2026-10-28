import 'package:flutter/material.dart';
import '../../domain/activities/activity.dart';
import 'activity_wrap_up_screen.dart';

class AnimalSpotterGameScreen extends StatefulWidget {
  final String? childNickname;
  final String? childId;
  final String? subjectUid;

  const AnimalSpotterGameScreen({
    super.key,
    this.childNickname,
    this.childId,
    this.subjectUid,
  });

  @override
  State<AnimalSpotterGameScreen> createState() => _AnimalSpotterGameScreenState();
}

class _SpotterQuestion {
  final String prompt;
  final String hint;
  final String correctEmoji;
  final String correctName;
  final List<Map<String, String>> choices;

  const _SpotterQuestion({
    required this.prompt,
    required this.hint,
    required this.correctEmoji,
    required this.correctName,
    required this.choices,
  });
}

class _AnimalSpotterGameScreenState extends State<AnimalSpotterGameScreen> {
  static const List<_SpotterQuestion> _questions = [
    _SpotterQuestion(
      prompt: 'Who has a yellow fluffy mane and loves to ROAR?',
      hint: 'The king of the jungle!',
      correctEmoji: '🦁',
      correctName: 'Lion',
      choices: [
        {'emoji': '🦁', 'name': 'Lion'},
        {'emoji': '🐰', 'name': 'Bunny'},
        {'emoji': '🐢', 'name': 'Turtle'},
        {'emoji': '🦆', 'name': 'Duck'},
      ],
    ),
    _SpotterQuestion(
      prompt: 'Find the happy green jumper that goes "Ribbit ribbit"!',
      hint: 'It loves lily pads and water ponds.',
      correctEmoji: '🐸',
      correctName: 'Frog',
      choices: [
        {'emoji': '🐧', 'name': 'Penguin'},
        {'emoji': '🐸', 'name': 'Frog'},
        {'emoji': '🐘', 'name': 'Elephant'},
        {'emoji': '🦊', 'name': 'Fox'},
      ],
    ),
    _SpotterQuestion(
      prompt: 'Spot the playful puppy that barks "Woof woof" and wags its tail!',
      hint: 'Man\'s best furry friend.',
      correctEmoji: '🐶',
      correctName: 'Puppy',
      choices: [
        {'emoji': '🐱', 'name': 'Cat'},
        {'emoji': '🐼', 'name': 'Panda'},
        {'emoji': '🐶', 'name': 'Puppy'},
        {'emoji': '🐨', 'name': 'Koala'},
      ],
    ),
    _SpotterQuestion(
      prompt: 'Which animal has a very long trunk and huge floppy ears?',
      hint: 'The gentlest giant in the wild.',
      correctEmoji: '🐘',
      correctName: 'Elephant',
      choices: [
        {'emoji': '🐘', 'name': 'Elephant'},
        {'emoji': '🦒', 'name': 'Giraffe'},
        {'emoji': '🐵', 'name': 'Monkey'},
        {'emoji': '🦓', 'name': 'Zebra'},
      ],
    ),
    _SpotterQuestion(
      prompt: 'Find the bird dressed in a black and white tuxedo that waddles on ice!',
      hint: 'It lives where it is very cold and snows!',
      correctEmoji: '🐧',
      correctName: 'Penguin',
      choices: [
        {'emoji': '🦉', 'name': 'Owl'},
        {'emoji': '🦄', 'name': 'Unicorn'},
        {'emoji': '🐧', 'name': 'Penguin'},
        {'emoji': '🦩', 'name': 'Flamingo'},
      ],
    ),
  ];

  int _currentIndex = 0;
  int _score = 0;
  String? _selectedEmoji;
  bool? _isCorrect;
  bool _isAnswered = false;

  void _handleChoice(String emoji) {
    if (_isAnswered) return;

    final q = _questions[_currentIndex];
    final correct = emoji == q.correctEmoji;

    setState(() {
      _selectedEmoji = emoji;
      _isCorrect = correct;
      _isAnswered = true;
      if (correct) _score++;
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isAnswered = false;
          _selectedEmoji = null;
          _isCorrect = null;
          _currentIndex++;
        });
      }
    });
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _selectedEmoji = null;
      _isCorrect = null;
      _isAnswered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleChild = widget.childNickname ?? 'Explorer';

    if (_currentIndex >= _questions.length) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F4FD),
        appBar: AppBar(
          title: Text(
            '$titleChild\'s Animal Spotter',
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Quicksand'),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B32E8).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆 ⭐ 🌟', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'Listening Champion!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Quicksand',
                    color: Color(0xFF1E1546),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You spotted $_score out of ${_questions.length} animals correctly!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                final activity = Activity(
                  id: 'game_animal_spotter',
                  version: 1,
                  status: 'published',
                  title: 'Animal & Character Spotter',
                  domain: 'vocabulary',
                  type: 'auditory_visual_match',
                  ageBand: '5_11',
                  audience: 'parent',
                  estMinutes: 5,
                  difficulty: 1,
                  goal: 'Link auditory speech prompts with visual animal vocabulary.',
                  steps: const ['Listen to the prompt and tap the matching animal.'],
                  parentTips: const ['Praise listening and repeat the target animal sound.'],
                  content: const {},
                  visualSupport: true,
                  strengthsMessage: 'Terrific listening and vocabulary!',
                );
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ActivityWrapUpScreen(
                      activity: activity,
                      durationS: 90,
                      childId: widget.childId,
                      subjectUid: widget.subjectUid,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B32E8), Color(0xFF7952FC)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF4321BD),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Claim Stars & Save Progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _restart,
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
                child: const Center(
                  child: Text(
                    'Play Again',
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
            const SizedBox(height: 12),
            TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Practice Zone'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FD),
      appBar: AppBar(
        title: Text(
          '$titleChild\'s Animal Spotter',
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Quicksand'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Round progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Round ${_currentIndex + 1} of ${_questions.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B32E8),
                      fontFamily: 'Quicksand',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC72C).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF57C00)),
                        const SizedBox(width: 4),
                        Text(
                          'Score: $_score',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  minHeight: 8,
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B32E8)),
                ),
              ),
              const SizedBox(height: 24),

              // Speech Prompt Bubble
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B32E8).withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF5B32E8).withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B32E8).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up_rounded, size: 16, color: Color(0xFF5B32E8)),
                          SizedBox(width: 6),
                          Text(
                            'LISTEN & SPOT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5B32E8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      q.prompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Quicksand',
                        color: Color(0xFF1E1546),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '💡 Clue: ${q.hint}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Feedback Banner if answered
              if (_isAnswered)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _isCorrect == true ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isCorrect == true ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCorrect == true ? Icons.check_circle_rounded : Icons.info_rounded,
                        color: _isCorrect == true ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCorrect == true ? 'Super Listening! That is right! ⭐' : 'Nice try! It was the ${q.correctName} 🌟',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isCorrect == true ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                        ),
                      ),
                    ],
                  ),
                ),

              // 4 Choice Cards Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: q.choices.map((choice) {
                    final isThisSelected = _selectedEmoji == choice['emoji'];
                    Color cardBorder = Colors.transparent;
                    Color cardBg = Colors.white;

                    if (_isAnswered) {
                      if (choice['emoji'] == q.correctEmoji) {
                        cardBorder = const Color(0xFF4CAF50);
                        cardBg = const Color(0xFFE8F5E9);
                      } else if (isThisSelected) {
                        cardBorder = const Color(0xFFFF5252);
                        cardBg = const Color(0xFFFFEBEE);
                      }
                    }

                    return GestureDetector(
                      onTap: () => _handleChoice(choice['emoji']!),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cardBorder != Colors.transparent
                                ? cardBorder
                                : const Color(0xFF5B32E8).withValues(alpha: 0.15),
                            width: cardBorder != Colors.transparent ? 3 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5B32E8).withValues(alpha: 0.08),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              choice['emoji']!,
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              choice['name']!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Quicksand',
                                color: Color(0xFF1E1546),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
