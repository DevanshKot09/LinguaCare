import 'package:flutter/material.dart';
import '../../domain/activities/activity.dart';
import 'activity_player_screen.dart';

class ActivityDetailScreen extends StatelessWidget {
  final Activity activity;
  final String? childId;
  final String? subjectUid;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
    this.childId,
    this.subjectUid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(activity.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(activity.domain.toUpperCase())),
                Chip(label: Text('${activity.estMinutes} mins')),
                Chip(label: Text('Difficulty ${activity.difficulty}/3')),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              activity.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              activity.goal,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const Divider(height: 32),
            const Text('How it Works', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...activity.steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Expanded(child: Text(step, style: const TextStyle(fontSize: 15))),
                    ],
                  ),
                )),
            if (activity.parentTips.isNotEmpty) ...[
              const Divider(height: 32),
              const Text('How to Join In (Parent & Caregiver Tips)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: activity.parentTips
                      .map((tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.tips_and_updates_rounded, size: 20, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(child: Text(tip, style: const TextStyle(fontSize: 15))),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ActivityPlayerScreen(
                      activity: activity,
                      childId: childId,
                      subjectUid: subjectUid,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Practice Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
