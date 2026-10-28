import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:linguacare/domain/screening/instrument.dart';
import 'package:linguacare/domain/screening/screening_result.dart';

class ScreeningDomainChart extends StatelessWidget {
  final Instrument instrument;
  final ScreeningResult result;

  const ScreeningDomainChart({
    super.key,
    required this.instrument,
    required this.result,
  });

  Color _getColorForScore(double score) {
    if (score <= 50.0) {
      return const Color(0xFF10B981); // Emerald / Strength
    } else if (score <= 75.0) {
      return const Color(0xFFF59E0B); // Amber / Some signs
    } else {
      return const Color(0xFFEF4444); // Red / More signs
    }
  }

  String _getDomainShortName(String domainId) {
    switch (domainId) {
      case 'understanding':
        return 'Under-\nstanding';
      case 'words':
        return 'Vocab-\nulary';
      case 'grammar':
        return 'Gram-\nmar';
      case 'stories':
        return 'Narr-\native';
      case 'conversation':
        return 'Social /\nPragmatics';
      default:
        return domainId.length > 6 ? '${domainId.substring(0, 6)}.' : domainId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final domains = instrument.domains;
    if (domains.isEmpty) return const SizedBox.shrink();

    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < domains.length; i++) {
      final domain = domains[i];
      final score = result.domainScores[domain.id] ?? 0.0;
      final color = _getColorForScore(score);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: score.clamp(0.0, 100.0),
              color: color,
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: Colors.grey.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
                  Icons.bar_chart_rounded,
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
                      'Domain Score Breakdown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Relative indicator of difficulty (Lower is stronger)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: 100,
                minY: 0,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= domains.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _getDomainShortName(domains[idx].id),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend row
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF10B981), 'Strength / Typical (0-50%)'),
              _buildLegendItem(const Color(0xFFF59E0B), 'Some Signs (51-75%)'),
              _buildLegendItem(const Color(0xFFEF4444), 'More Signs (76-100%)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
