import 'package:flutter/material.dart';
import 'package:linguacare/domain/screening/instrument.dart';
import 'package:linguacare/domain/screening/screening_result.dart';
import '../data/screening_milestone_data.dart';

class MilestoneBreakdownMatrix extends StatelessWidget {
  final Instrument instrument;
  final ScreeningResult result;

  const MilestoneBreakdownMatrix({
    super.key,
    required this.instrument,
    required this.result,
  });

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

  Color _getLevelColor(String level) {
    switch (level) {
      case 'strength':
        return const Color(0xFF10B981);
      case 'typical_range':
        return const Color(0xFF2563EB);
      case 'some_signs':
        return const Color(0xFFF59E0B);
      case 'more_signs':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _getLevelLabel(String level) {
    switch (level) {
      case 'strength':
        return 'Thriving / Strength';
      case 'typical_range':
        return 'Typical Milestone';
      case 'some_signs':
        return 'Emerging / Some Signs';
      case 'more_signs':
        return 'Needs Focused Practice';
      default:
        return 'Pending Data';
    }
  }

  @override
  Widget build(BuildContext context) {
    final domains = instrument.domains;
    final ageBand = instrument.ageBand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5B32E8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                color: Color(0xFF5B32E8),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developmental Milestone Matrix',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Clinical age benchmark vs observed language profile',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...domains.map((domain) {
          final level = result.domainLevels[domain.id] ?? 'insufficient_data';
          final levelColor = _getLevelColor(level);
          final levelLabel = _getLevelLabel(level);
          final milestone = ScreeningMilestoneData.getMilestone(domain.id, ageBand);
          final score = result.domainScores[domain.id] ?? 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: levelColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDomainIcon(domain.id),
                    color: levelColor,
                    size: 24,
                  ),
                ),
                title: Text(
                  domain.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          levelLabel,
                          style: TextStyle(
                            color: levelColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Score: ${score.toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Target Milestone for Age:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF5B32E8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          milestone.expectedMilestone,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Typical Everyday Example:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          milestone.example,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EEFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: Color(0xFF5B32E8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  milestone.recommendation,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF332070),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
