import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';
import '../../domain/activities/activity.dart';
import '../../domain/activities/activity_providers.dart';
import '../../domain/activities/activity_session.dart';
import '../../domain/settings/app_settings.dart';

class ActivityWrapUpScreen extends ConsumerStatefulWidget {
  final Activity activity;
  final int durationS;
  final String? childId;
  final String? subjectUid;

  const ActivityWrapUpScreen({
    super.key,
    required this.activity,
    required this.durationS,
    this.childId,
    this.subjectUid,
  });

  @override
  ConsumerState<ActivityWrapUpScreen> createState() => _ActivityWrapUpScreenState();
}

class _ActivityWrapUpScreenState extends ConsumerState<ActivityWrapUpScreen> {
  int? _successLevel = 4; // default good practice
  String _supportLevel = 'independent';
  bool _isSaving = false;

  final Map<int, String> _successLabels = {
    1: 'Needs lots of support',
    2: 'Getting there',
    3: 'Good practice',
    4: 'Very smooth',
    5: 'Mastered independently',
  };

  Future<void> _saveAndFinish({bool skippedRating = false}) async {
    setState(() => _isSaving = true);

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final session = ActivitySession(
      childId: widget.childId,
      subjectUid: widget.subjectUid,
      actorUid: userId,
      activityId: widget.activity.id,
      activityVersion: widget.activity.version,
      domain: widget.activity.domain,
      startedAt: DateTime.now().subtract(Duration(seconds: widget.durationS)),
      durationS: widget.durationS,
      completed: true,
      successLevel: skippedRating ? null : _successLevel,
      supportLevel: skippedRating ? null : _supportLevel,
      clientId: const Uuid().v4(),
    );

    try {
      final repo = ref.read(activityRepositoryProvider);
      await repo.saveSession(session);
    } catch (_) {
      // Handled in repository offline queue fallback
    }

    if (!mounted) return;
    // Pop back to home / practise tab
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final reduceMotion = MediaQuery.of(context).accessibleNavigation;

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Summary')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            if (settings.rewardAnimationsEnabled && !reduceMotion) ...[
              SizedBox(
                height: 120,
                child: Lottie.network(
                  'https://assets2.lottiefiles.com/packages/lf20_hx7ccqwn.json',
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.star_rounded, size: 64, color: Colors.amber),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              widget.activity.strengthsMessage,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'How did this practice session go?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Success rating 1-5 with words
            RadioGroup<int>(
              groupValue: _successLevel,
              onChanged: (v) => setState(() => _successLevel = v),
              child: Column(
                children: _successLabels.entries.map((entry) {
                  final val = entry.key;
                  final label = entry.value;
                  final isSelected = _successLevel == val;

                  return Semantics(
                    selected: isSelected,
                    child: RadioListTile<int>(
                      title: Text(label),
                      subtitle: Text('Rating $val / 5'),
                      value: val,
                      tileColor: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2) : null,
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 32),
            const Text(
              'Support level needed during practice:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _supportLevel,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'independent', child: Text('On their own / Independent')),
                DropdownMenuItem(value: 'prompted', child: Text('With a little help / Prompted')),
                DropdownMenuItem(value: 'heavy', child: Text('With a lot of help / Heavy support')),
              ],
              onChanged: (v) => setState(() => _supportLevel = v ?? 'independent'),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : () => _saveAndFinish(skippedRating: false),
              child: _isSaving ? const CircularProgressIndicator() : const Text('Save & Finish'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isSaving ? null : () => _saveAndFinish(skippedRating: true),
              child: const Text('Skip rating & save'),
            ),
          ],
        ),
      ),
    );
  }
}
