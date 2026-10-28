import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/activities/activity.dart';
import '../../domain/activities/activity_providers.dart';
import '../../domain/activities/daily_plan.dart';
import 'activity_detail_screen.dart';

class ActivitiesHomeScreen extends ConsumerStatefulWidget {
  final String? childId;
  final String? subjectUid;
  final String ageBand;
  final String audience;

  const ActivitiesHomeScreen({
    super.key,
    this.childId,
    this.subjectUid,
    required this.ageBand,
    required this.audience,
  });

  @override
  ConsumerState<ActivitiesHomeScreen> createState() => _ActivitiesHomeScreenState();
}

class _ActivitiesHomeScreenState extends ConsumerState<ActivitiesHomeScreen> {
  String? _selectedDomain;

  @override
  Widget build(BuildContext context) {
    final allActivitiesAsync = ref.watch(allActivitiesProvider);
    final dailyPlanAsync = widget.childId != null
        ? ref.watch(dailyPlanForChildProvider(widget.childId!))
        : widget.subjectUid != null
            ? ref.watch(dailyPlanForSelfProvider(widget.subjectUid!))
            : null;

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [

        Text(
          'Today\'s Practice',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Daily Plan Card
        if (dailyPlanAsync != null)
          dailyPlanAsync.when(
            data: (plan) => _buildDailyPlanCard(context, plan),
            loading: () => const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))),
            error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Could not load daily plan: $e'))),
          ),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🎮 Interactive Game Zone',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Quicksand',
                  ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/builder/custom-activity?role=${widget.audience}'),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('Custom'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.ageBand == '5_11') ...[
          _buildGameCard(
            title: 'Cartoon Memory Match',
            subtitle: 'Flip & match speech character cards',
            icon: Icons.style_rounded,
            emoji: '🦁',
            color: const Color(0xFF5B32E8),
            onTap: () => context.push(
              '/games/cartoon-memory?childId=${widget.childId ?? ''}&subjectUid=${widget.subjectUid ?? ''}',
            ),
          ),
          const SizedBox(height: 10),
          _buildGameCard(
            title: 'Animal & Character Spotter',
            subtitle: 'Listen to speech prompts & tap the character',
            icon: Icons.hearing_rounded,
            emoji: '🐸',
            color: const Color(0xFF00C4B4),
            onTap: () => context.push(
              '/games/animal-spotter?childId=${widget.childId ?? ''}&subjectUid=${widget.subjectUid ?? ''}',
            ),
          ),
        ] else if (widget.ageBand == '11_18') ...[
          _buildGameCard(
            title: 'Sentence Reconstruction',
            subtitle: 'Unscramble complex clauses & grammar syntax',
            icon: Icons.text_snippet_rounded,
            emoji: '🧩',
            color: const Color(0xFFFF9800),
            onTap: () => context.push(
              '/games/sentence-reconstruction?childId=${widget.childId ?? ''}&subjectUid=${widget.subjectUid ?? ''}',
            ),
          ),
        ],
        const SizedBox(height: 10),
        _buildGameCard(
          title: 'Custom Therapy Builder',
          subtitle: 'Create flashcards & custom word questions',
          icon: Icons.edit_note_rounded,
          emoji: '✏️',
          color: const Color(0xFF7E57C2),
          onTap: () => context.push('/builder/custom-activity?role=${widget.audience}'),
        ),

        const SizedBox(height: 24),
        Text(
          'Explore Activities',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Domain filter chips
        _buildDomainFilterChips(),
        const SizedBox(height: 16),

        allActivitiesAsync.when(
          data: (activities) {
            // Filter by age band and audience, and release gating
            final filtered = activities.where((a) {
              if (a.ageBand != widget.ageBand && a.ageBand != 'adult') return false;
              if (a.audience != widget.audience && audienceMismatchAllowed(widget.audience, a.audience)) return false;
              if (_selectedDomain != null && a.domain != _selectedDomain) return false;
              if (kReleaseMode && a.status != 'published') return false;
              return true;
            }).toList();

            if (filtered.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.sports_esports_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'Activities are coming soon',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check back later or explore the Clinical Speech Tools for guided strategies.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => context.push('/tools'),
                        child: const Text('Explore Speech Tools'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: filtered.map((activity) => _buildActivityCard(context, activity)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading activities: $e'),
        ),
      ],
    );
  }

  bool audienceMismatchAllowed(String currentAudience, String activityAudience) {
    if (currentAudience == 'parent' && activityAudience == 'adult') return true;
    return false;
  }

  Widget _buildDailyPlanCard(BuildContext context, DailyPlan plan) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.amber, size: 28),
                    SizedBox(width: 8),
                    Text('Recommended for Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Chip(label: Text('~${plan.totalMinutes} min total')),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Gentle, short practice activities tailored to support communication growth.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...plan.activities.map((act) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(iconForDomain(act.domain), color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(act.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${act.estMinutes} mins • ${act.domain.toUpperCase()}'),
                  trailing: ElevatedButton(
                    onPressed: () => _startActivity(context, act),
                    child: const Text('Start'),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainFilterChips() {
    const domains = ['vocabulary', 'understanding', 'narrative', 'grammar', 'conversation', 'confidence'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Domains'),
            selected: _selectedDomain == null,
            onSelected: (_) => setState(() => _selectedDomain = null),
          ),
          const SizedBox(width: 8),
          ...domains.map((dom) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(dom.toUpperCase()),
                  selected: _selectedDomain == dom,
                  onSelected: (selected) => setState(() => _selectedDomain = selected ? dom : null),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(activity.domain.toUpperCase()),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                Row(
                  children: [
                    if (activity.visualSupport)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.visibility_rounded, size: 18, color: Colors.grey),
                      ),
                    Text('${activity.estMinutes} mins', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(activity.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(activity.goal, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startActivity(context, activity),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('View & Practise'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData iconForDomain(String domain) {
    switch (domain) {
      case 'vocabulary':
        return Icons.abc_rounded;
      case 'understanding':
        return Icons.hearing_rounded;
      case 'narrative':
        return Icons.auto_stories_rounded;
      case 'grammar':
        return Icons.rule_rounded;
      case 'conversation':
        return Icons.chat_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String emoji,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      offset: const Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Text(
                  'Play',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startActivity(BuildContext context, Activity activity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(
          activity: activity,
          childId: widget.childId,
          subjectUid: widget.subjectUid,
        ),
      ),
    );
  }
}
