import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/activities/activity.dart';
import 'activity_wrap_up_screen.dart';

class CartoonMemoryGameScreen extends StatefulWidget {
  final String? childNickname;
  final String? childId;
  final String? subjectUid;

  const CartoonMemoryGameScreen({
    super.key,
    this.childNickname,
    this.childId,
    this.subjectUid,
  });

  @override
  State<CartoonMemoryGameScreen> createState() => _CartoonMemoryGameScreenState();
}

class _CardItem {
  final int id;
  final String emoji;
  final String name;
  final Color color;
  bool isFlipped;
  bool isMatched;

  _CardItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.color,
  })  : isFlipped = false,
        isMatched = false;
}

class _CartoonMemoryGameScreenState extends State<CartoonMemoryGameScreen> {
  static const List<Map<String, dynamic>> _sourcePairs = [
    {'emoji': '🦁', 'name': 'Leo Lion', 'color': Color(0xFFFFB300)},
    {'emoji': '🐧', 'name': 'Pip Penguin', 'color': Color(0xFF00C4B4)},
    {'emoji': '🐻', 'name': 'Bella Bear', 'color': Color(0xFF8D6E63)},
    {'emoji': '🐬', 'name': 'Dolphin', 'color': Color(0xFF0288D1)},
    {'emoji': '🐵', 'name': 'Milo Monkey', 'color': Color(0xFFFF7043)},
    {'emoji': '🐸', 'name': 'Flip Frog', 'color': Color(0xFF4CAF50)},
  ];

  late List<_CardItem> _cards;
  int? _firstSelectedIndex;
  bool _isProcessing = false;
  int _moves = 0;
  int _pairsFound = 0;
  bool _isComplete = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _timer?.cancel();
    _moves = 0;
    _pairsFound = 0;
    _isComplete = false;
    _elapsedSeconds = 0;
    _firstSelectedIndex = null;
    _isProcessing = false;

    final List<_CardItem> list = [];
    int idCounter = 0;
    for (final s in _sourcePairs) {
      list.add(_CardItem(
        id: idCounter++,
        emoji: s['emoji'] as String,
        name: s['name'] as String,
        color: s['color'] as Color,
      ));
      list.add(_CardItem(
        id: idCounter++,
        emoji: s['emoji'] as String,
        name: s['name'] as String,
        color: s['color'] as Color,
      ));
    }
    list.shuffle(Random());
    _cards = list;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isComplete) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });

    setState(() {});
  }

  void _handleCardTap(int index) {
    if (_isProcessing || _cards[index].isFlipped || _cards[index].isMatched) return;

    setState(() {
      _cards[index].isFlipped = true;
    });

    if (_firstSelectedIndex == null) {
      _firstSelectedIndex = index;
    } else {
      _moves++;
      final firstIdx = _firstSelectedIndex!;
      _firstSelectedIndex = null;

      if (_cards[firstIdx].emoji == _cards[index].emoji) {
        setState(() {
          _cards[firstIdx].isMatched = true;
          _cards[index].isMatched = true;
          _pairsFound++;
          if (_pairsFound == _sourcePairs.length) {
            _isComplete = true;
            _timer?.cancel();
          }
        });
      } else {
        _isProcessing = true;
        Future.delayed(const Duration(milliseconds: 850), () {
          if (mounted) {
            setState(() {
              _cards[firstIdx].isFlipped = false;
              _cards[index].isFlipped = false;
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleChild = widget.childNickname ?? 'Explorer';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FD),
      appBar: AppBar(
        title: Text(
          '$titleChild\'s Memory Match',
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Quicksand'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Restart Game',
            onPressed: _startNewGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBadge(
                    icon: Icons.touch_app_rounded,
                    label: 'Moves',
                    value: '$_moves',
                    color: const Color(0xFF5B32E8),
                  ),
                  _buildStatBadge(
                    icon: Icons.star_rounded,
                    label: 'Matches',
                    value: '$_pairsFound / ${_sourcePairs.length}',
                    color: const Color(0xFFFF9800),
                  ),
                  _buildStatBadge(
                    icon: Icons.timer_rounded,
                    label: 'Time',
                    value: '${_elapsedSeconds}s',
                    color: const Color(0xFF00C4B4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _isComplete
                    ? _buildVictoryCard()
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _cards.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final card = _cards[index];
                          return _buildCardWidget(card, index);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, fontFamily: 'Quicksand'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardWidget(_CardItem card, int index) {
    final showFace = card.isFlipped || card.isMatched;

    return GestureDetector(
      onTap: () => _handleCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: showFace ? card.color.withValues(alpha: 0.15) : const Color(0xFF5B32E8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: showFace ? card.color : const Color(0xFF4321BD),
            width: showFace ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: showFace ? card.color.withValues(alpha: 0.2) : const Color(0xFF351996),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: showFace
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      card.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Quicksand',
                        color: card.color.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFC72C),
                      size: 36,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'TAP ME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildVictoryCard() {
    return Center(
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
            const Text(
              '🎉 ⭐ 🎉',
              style: TextStyle(fontSize: 44),
            ),
            const SizedBox(height: 12),
            const Text(
              'Super Speech Star!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Quicksand',
                color: Color(0xFF1E1546),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You matched all 6 pairs in $_moves moves and $_elapsedSeconds seconds!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                final activity = Activity(
                  id: 'game_cartoon_memory',
                  version: 1,
                  status: 'published',
                  title: 'Cartoon Memory Match',
                  domain: 'comprehension',
                  type: 'memory_match',
                  ageBand: '5_11',
                  audience: 'parent',
                  estMinutes: 5,
                  difficulty: 2,
                  goal: 'Strengthen working memory and visual-word association.',
                  steps: const ['Flip cards and match pairs.'],
                  parentTips: const ['Encourage naming the characters out loud.'],
                  content: const {},
                  visualSupport: true,
                  strengthsMessage: 'Super speech recall!',
                );
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ActivityWrapUpScreen(
                      activity: activity,
                      durationS: _elapsedSeconds > 0 ? _elapsedSeconds : 60,
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
              onTap: _startNewGame,
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
    );
  }
}
