import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/screening_repository_impl.dart';
import '../../domain/screening/instrument.dart';
import '../../domain/screening/scoring_engine.dart';
import '../../l10n/app_localizations.dart';

class ScreeningQuestionScreen extends ConsumerStatefulWidget {
  final String instrumentId;
  final String? childId;

  const ScreeningQuestionScreen({
    Key? key,
    required this.instrumentId,
    this.childId,
  }) : super(key: key);

  @override
  ConsumerState<ScreeningQuestionScreen> createState() => _ScreeningQuestionScreenState();
}

class _ScreeningQuestionScreenState extends ConsumerState<ScreeningQuestionScreen> {
  int _currentIndex = 0;
  final Map<String, int?> _answers = {};
  bool _isLoading = true;
  Instrument? _instrument;

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
      });
    } else {
      _submitScreening();
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
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
          title: Text('Question ${_currentIndex + 1} of ${items.length}'),
          actions: [
            TextButton.icon(
              onPressed: _showPauseDialog,
              icon: const Icon(Icons.pause),
              label: Text(l10n.pauseAndExit),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: LinearProgressIndicator(value: progress),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentItem.text,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    children: [
                      _buildOptionTile(0, l10n.optionRarely, currentAnswer),
                      const SizedBox(height: 12),
                      _buildOptionTile(1, l10n.optionSometimes, currentAnswer),
                      const SizedBox(height: 12),
                      _buildOptionTile(2, l10n.optionOften, currentAnswer),
                      const SizedBox(height: 12),
                      _buildOptionTile(3, l10n.optionAlmostAlways, currentAnswer),
                      const SizedBox(height: 24),
                      Divider(color: Theme.of(context).colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      _buildNotSureTile(currentAnswer),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: currentAnswer != null ? _nextQuestion : null,
                    child: Text(
                      _currentIndex == items.length - 1 ? 'Finish & View Report' : l10n.next,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildOptionTile(int value, String text, int? currentAnswer) {
    final isSelected = currentAnswer == value;
    return InkWell(
      onTap: () => _onAnswerSelected(_instrument!.items[_currentIndex].id, value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotSureTile(int? currentAnswer) {
    return InkWell(
      onTap: () => _onAnswerSelected(_instrument!.items[_currentIndex].id, null),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.optionNotSure,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
