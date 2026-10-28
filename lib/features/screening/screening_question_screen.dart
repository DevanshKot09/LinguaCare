import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/screening_repository_impl.dart';
import '../../domain/screening/instrument.dart';
import '../../domain/screening/scoring_engine.dart';
import '../../l10n/app_localizations.dart';
import 'data/screening_milestone_data.dart';

class ScreeningQuestionScreen extends ConsumerStatefulWidget {
  final String instrumentId;
  final String? childId;

  const ScreeningQuestionScreen({
    super.key,
    required this.instrumentId,
    this.childId,
  });

  @override
  ConsumerState<ScreeningQuestionScreen> createState() => _ScreeningQuestionScreenState();
}

class _ScreeningQuestionScreenState extends ConsumerState<ScreeningQuestionScreen> {
  int _currentIndex = 0;
  final Map<String, int?> _answers = {};
  bool _isLoading = true;
  Instrument? _instrument;
  bool _showExample = false;

  @override
  void initState() {
    super.initState();
    _loadInstrumentAndDraft();
  }

  Future<void> _loadInstrumentAndDraft() async {
    try {
      final repo = ScreeningRepositoryImpl();
      final instrument = await repo.loadInstrument(widget.instrumentId);
      final draft = await repo.loadDraftAnswers(widget.instrumentId);
      if (!mounted) return;
      setState(() {
        _instrument = instrument;
        _answers.addAll(draft);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDraft() async {
    final repo = ScreeningRepositoryImpl();
    await repo.saveDraftAnswers(widget.instrumentId, _answers);
  }

  void _onAnswerSelected(String itemId, int? score) {
    setState(() {
      _answers[itemId] = score;
    });
    _saveDraft();
  }

  void _nextQuestion() {
    if (_instrument == null) return;
    if (_currentIndex < _instrument!.items.length - 1) {
      setState(() {
        _currentIndex++;
        _showExample = false;
      });
    } else {
      _submitScreening();
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showExample = false;
      });
    } else {
      _showPauseDialog();
    }
  }

  Future<void> _showPauseDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final shouldPause = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pauseConfirmTitle),
        content: Text(l10n.pauseConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.continueCheck),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.resumeLater),
          ),
        ],
      ),
    );

    if (shouldPause == true && mounted) {
      await _saveDraft();
      if (!mounted) return;
      context.pop();
    }
  }

  Future<void> _submitScreening() async {
    if (_instrument == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final session = ScoringEngine.evaluate(
      instrument: _instrument!,
      answers: _answers,
      respondentUid: user.uid,
      respondentRole: widget.childId != null ? 'parent' : 'adult',
      childId: widget.childId,
      subjectUid: widget.childId == null ? user.uid : null,
    );

    try {
      final repo = ScreeningRepositoryImpl();
      await repo.saveScreeningResult(session);
      await repo.clearDraftAnswers(widget.instrumentId);

      if (mounted) {
        context.push('/screening/report?instrumentId=${widget.instrumentId}&childId=${widget.childId ?? ''}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving screening: $e')),
        );
      }
    }
  }

  String _getDomainName(String domainId) {
    if (_instrument == null) return domainId;
    final found = _instrument!.domains.where((d) => d.id == domainId);
    return found.isNotEmpty ? found.first.name : domainId;
  }

  IconData _getDomainIcon(String domainId) {
    switch (domainId) {
      case 'understanding':
        return Icons.hearing_rounded;
      case 'words':
        return Icons.chat_bubble_outline_rounded;
      case 'grammar':
        return Icons.menu_book_rounded;
      case 'stories':
        return Icons.auto_stories_rounded;
      case 'conversation':
        return Icons.groups_rounded;
      default:
        return Icons.psychology_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading || _instrument == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final items = _instrument!.items;
    final currentItem = items[_currentIndex];
    final currentAnswer = _answers[currentItem.id];
    final progress = (_currentIndex + 1) / items.length;
    final domainName = _getDomainName(currentItem.domain);
    final exampleText = ScreeningMilestoneData.itemExamples[currentItem.id];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showPauseDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _prevQuestion,
            tooltip: 'Back',
          ),
          title: Text(
            'Question ${_currentIndex + 1} of ${items.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          actions: [
            TextButton.icon(
              onPressed: _showPauseDialog,
              icon: const Icon(Icons.pause, size: 18),
              label: Text(l10n.pauseAndExit),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: LinearProgressIndicator(
              value: progress,
              color: const Color(0xFF5B32E8),
              backgroundColor: const Color(0xFF5B32E8).withValues(alpha: 0.15),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Domain Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B32E8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getDomainIcon(currentItem.domain),
                        size: 16,
                        color: const Color(0xFF5B32E8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        domainName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B32E8),
                        ),
                      ),
                      if (currentItem.urgent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Medical Priority',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Question Title
                Text(
                  currentItem.text,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 12),

                // Expandable Real-World Example
                if (exampleText != null) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showExample = !_showExample;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _showExample
                            ? const Color(0xFFF3EEFF)
                            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showExample
                              ? const Color(0xFF5B32E8).withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _showExample ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                                size: 18,
                                color: const Color(0xFF5B32E8),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '💡 Real-World Example & Clarification',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5B32E8),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _showExample ? Icons.expand_less : Icons.expand_more,
                                size: 18,
                                color: const Color(0xFF5B32E8),
                              ),
                            ],
                          ),
                          if (_showExample) ...[
                            const SizedBox(height: 8),
                            Text(
                              exampleText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF281850),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Options List
                Expanded(
                  child: ListView(
                    children: [
                      _buildTactileOptionTile(0, l10n.optionRarely, currentAnswer),
                      const SizedBox(height: 10),
                      _buildTactileOptionTile(1, l10n.optionSometimes, currentAnswer),
                      const SizedBox(height: 10),
                      _buildTactileOptionTile(2, l10n.optionOften, currentAnswer),
                      const SizedBox(height: 10),
                      _buildTactileOptionTile(3, l10n.optionAlmostAlways, currentAnswer),
                      const SizedBox(height: 16),
                      Divider(color: Theme.of(context).colorScheme.outlineVariant),
                      const SizedBox(height: 8),
                      _buildNotSureTile(currentAnswer),
                    ],
                  ),
                ),

                // Next / Finish Button
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: currentAnswer != null
                          ? [
                              const BoxShadow(
                                color: Color(0xFF371B99),
                                offset: Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: currentAnswer != null ? _nextQuestion : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B32E8),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentIndex == items.length - 1 ? 'Finish & View Clinical Report' : l10n.next,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTactileOptionTile(int value, String text, int? currentAnswer) {
    final isSelected = currentAnswer == value;
    final primaryColor = const Color(0xFF5B32E8);

    return InkWell(
      onTap: () => _onAnswerSelected(_instrument!.items[_currentIndex].id, value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF3EEFF)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? primaryColor : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF2E1970) : Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotSureTile(int? currentAnswer) {
    final isSelected = currentAnswer == null && _answers.containsKey(_instrument!.items[_currentIndex].id);
    return InkWell(
      onTap: () => _onAnswerSelected(_instrument!.items[_currentIndex].id, null),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.grey.shade700 : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: isSelected ? Colors.grey.shade900 : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.optionNotSure,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.grey.shade900 : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
