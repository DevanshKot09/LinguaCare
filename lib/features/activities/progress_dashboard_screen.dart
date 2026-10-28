import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/activities/activity_providers.dart';
import '../../domain/activities/activity_session.dart';
import '../../domain/activities/progress_aggregator.dart';

class ProgressDashboardScreen extends ConsumerWidget {
  final String? childId;
  final String? subjectUid;
  final String title;

  const ProgressDashboardScreen({
    super.key,
    this.childId,
    this.subjectUid,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = childId != null
        ? ref.watch(progressForChildProvider(childId!))
        : subjectUid != null
            ? ref.watch(progressForSelfProvider(subjectUid!))
            : null;

    final sessionsAsync = childId != null
        ? ref.watch(activitySessionsForChildProvider(childId!))
        : subjectUid != null
            ? ref.watch(activitySessionsForSelfProvider(subjectUid!))
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: progressAsync == null
            ? const Center(child: Text('No progress data available.'))
            : progressAsync.when(
                data: (progress) {
                  final sessions = sessionsAsync?.asData?.value ?? [];
                  return _buildDashboard(context, progress, sessions);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading progress: $e')),
              ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    ProgressSummary progress,
    List<ActivitySession> sessions,
  ) {
    final primaryColor = const Color(0xFF5B32E8);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      children: [
        // Reassurance Note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.volunteer_activism_outlined, color: primaryColor, size: 24),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Progress is not linear. Consistent, playful practice builds everyday communication confidence over time.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF281850),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Summary Metric Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.sports_esports_rounded,
                iconColor: const Color(0xFF10B981),
                value: '${progress.totalSessions}',
                label: 'Total Sessions',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.timer_rounded,
                iconColor: const Color(0xFFF59E0B),
                value: '${progress.totalMinutes}',
                label: 'Total Minutes',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Weekly Streak & Practice Consistency
        _buildWeeklyStreakCard(context, sessions),
        const SizedBox(height: 20),

        // Recent Trend & Clinical Observation
        Text(
          'Clinical Observation & Trend',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B32E8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF5B32E8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  progress.trendMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Domain Practice Summary
        Text(
          'Communication Domain Mastery',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        if (progress.domainSummaries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: const Column(
              children: [
                Icon(Icons.auto_stories_outlined, size: 40, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No practice sessions recorded yet.\nStart an interactive game or daily activity to track progress here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.4),
                ),
              ],
            ),
          )
        else
          ...progress.domainSummaries.values.map((dom) => _buildDomainCard(context, dom)),

        const SizedBox(height: 24),

        // Recent Activity Sessions History
        if (sessions.isNotEmpty) ...[
          Text(
            'Recent Completed Sessions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...sessions.take(5).map((session) => _buildSessionLogCard(context, session)),
          const SizedBox(height: 16),
        ],

        // Action Buttons
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF371B99),
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => context.go('/activities'),
            icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
            label: const Text('Start Practice in Game Zone'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B32E8),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            final q = childId != null ? 'childId=$childId' : 'subjectUid=$subjectUid';
            context.push('/screening/history?$q');
          },
          icon: const Icon(Icons.history_rounded),
          label: const Text('View Screening History'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStreakCard(BuildContext context, List<ActivitySession> sessions) {
    final now = DateTime.now();
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final currentWeekday = now.weekday; // 1 = Mon, 7 = Sun

    // Determine active days in the current week
    final activeWeekdays = <int>{};
    for (final s in sessions) {
      final diff = now.difference(s.startedAt).inDays;
      if (diff <= 7) {
        activeWeekdays.add(s.startedAt.weekday);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🔥', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'Weekly Practice Streak',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Text(
                '${activeWeekdays.length}/7 Days Active',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B32E8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayNum = index + 1;
              final isToday = dayNum == currentWeekday;
              final isActive = activeWeekdays.contains(dayNum);

              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF10B981)
                          : isToday
                              ? const Color(0xFF5B32E8).withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: const Color(0xFF5B32E8), width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        isActive ? Icons.check_rounded : Icons.circle_outlined,
                        size: 18,
                        color: isActive
                            ? Colors.white
                            : isToday
                                ? const Color(0xFF5B32E8)
                                : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    daysOfWeek[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday
                          ? const Color(0xFF5B32E8)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainCard(BuildContext context, DomainProgressSummary dom) {
    final averagePercent = (dom.averageSuccess / 5.0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dom.domain.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B32E8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${dom.sessionCount} sessions',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B32E8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Average Mastery: ${(averagePercent * 100).toInt()}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                '${dom.averageSuccess.toStringAsFixed(1)} / 5.0',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: averagePercent,
              minHeight: 10,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                averagePercent >= 0.7
                    ? const Color(0xFF10B981)
                    : averagePercent >= 0.4
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.support_agent_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Support Level: ${dom.dominantSupportLevel.replaceAll('_', ' ')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionLogCard(BuildContext context, ActivitySession session) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final formattedDate = dateFormat.format(session.startedAt);
    final stars = session.successLevel ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5B32E8).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF5B32E8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.activityId.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '$formattedDate • ${session.durationS ~/ 60}m ${session.durationS % 60}s',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (stars > 0)
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
