import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'visual_schedule_screen.dart';
import 'instruction_simplifier_screen.dart';
import 'communication_card_screen.dart';
import 'adult_journal_screen.dart';
import '../../app/router/app_session.dart';

class ToolsHubScreen extends ConsumerWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionStateProvider);
    final isAdult = session.role == UserRole.adult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LinguaCare Tools Hub'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Practical support tools for everyday communication and organisation. Stored securely on your device only.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _ToolCard(
              title: 'Visual Schedule Builder',
              subtitle: 'Create calm step-by-step schedules with icons and daily check-ins.',
              icon: Icons.calendar_today_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VisualScheduleScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ToolCard(
              title: 'Instruction Simplifier',
              subtitle: 'Break down complex directions into clear, numbered steps. (Offline helper)',
              icon: Icons.format_list_numbered_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InstructionSimplifierScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ToolCard(
              title: 'Communication Card',
              subtitle: 'High-contrast full-screen cards for expressing communication needs quickly.',
              icon: Icons.record_voice_over_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CommunicationCardScreen()),
              ),
            ),
            if (isAdult) ...[
              const SizedBox(height: 12),
              _ToolCard(
                title: 'Adult Wellbeing Journal',
                subtitle: 'Record daily moods and situation notes with weekly summary charts.',
                icon: Icons.book_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdultJournalScreen()),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Note: All tool data is stored exclusively on this device and is never uploaded or shared unless you explicitly export or share via permitted features.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(subtitle, style: const TextStyle(fontSize: 13)),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
