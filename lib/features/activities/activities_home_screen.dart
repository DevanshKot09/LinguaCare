import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        if (!kReleaseMode)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Placeholder - not clinically reviewed (Debug Mode)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

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
                        'Check back later or explore the Learn Library for guided strategies.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Explore Learn Library'),
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
