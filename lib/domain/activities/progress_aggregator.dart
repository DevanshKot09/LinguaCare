import 'activity_session.dart';

class DomainProgressSummary {
  final String domain;
  final int sessionCount;
  final double averageSuccess; // 1-5
  final String dominantSupportLevel;

  const DomainProgressSummary({
    required this.domain,
    required this.sessionCount,
    required this.averageSuccess,
    required this.dominantSupportLevel,
  });
}

class ProgressSummary {
  final int totalSessions;
  final int totalMinutes;
  final Map<String, DomainProgressSummary> domainSummaries;
  final String trendMessage;

  const ProgressSummary({
    required this.totalSessions,
    required this.totalMinutes,
    required this.domainSummaries,
    required this.trendMessage,
  });
}

class ProgressAggregator {
  static ProgressSummary aggregate(List<ActivitySession> sessions) {
    if (sessions.isEmpty) {
      return const ProgressSummary(
        totalSessions: 0,
        totalMinutes: 0,
        domainSummaries: {},
        trendMessage: 'Not enough practice yet to show a trend',
      );
    }

    final totalSessions = sessions.length;
    final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationS) ~/ 60;

    // Group sessions by domain
    final byDomain = <String, List<ActivitySession>>{};
    for (final s in sessions) {
      byDomain.putIfAbsent(s.domain, () => []).add(s);
    }

    final domainSummaries = <String, DomainProgressSummary>{};
    byDomain.forEach((domain, domSessions) {
      final completedSessions = domSessions.where((s) => s.completed && s.successLevel != null).toList();
      final count = domSessions.length;
      double avgSuccess = 0.0;
      if (completedSessions.isNotEmpty) {
        final sumSuccess = completedSessions.fold<int>(0, (sum, s) => sum + (s.successLevel ?? 0));
        avgSuccess = sumSuccess / completedSessions.length;
      }

      // Dominant support level
      final supportCounts = <String, int>{};
      for (final s in domSessions) {
        if (s.supportLevel != null) {
          supportCounts[s.supportLevel!] = (supportCounts[s.supportLevel!] ?? 0) + 1;
        }
      }
      String dominantSupport = 'independent';
      int maxSupportCount = -1;
      supportCounts.forEach((sup, c) {
        if (c > maxSupportCount) {
          maxSupportCount = c;
          dominantSupport = sup;
        }
      });

      domainSummaries[domain] = DomainProgressSummary(
        domain: domain,
        sessionCount: count,
        averageSuccess: avgSuccess,
        dominantSupportLevel: dominantSupport,
      );
    });

    // Trend analysis: compare sessions in recent 7 days vs previous 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    final recentSessions = sessions.where((s) => s.startedAt.isAfter(sevenDaysAgo)).toList();
    final previousSessions = sessions.where((s) => s.startedAt.isAfter(fourteenDaysAgo) && s.startedAt.isBefore(sevenDaysAgo)).toList();

    String trendMessage = 'Not enough practice yet to show a trend';
    if (recentSessions.length >= 3 && previousSessions.length >= 3) {
      final recentAvg = recentSessions.where((s) => s.successLevel != null).fold<int>(0, (sum, s) => sum + s.successLevel!) / (recentSessions.where((s) => s.successLevel != null).length.clamp(1, 999));
      final prevAvg = previousSessions.where((s) => s.successLevel != null).fold<int>(0, (sum, s) => sum + s.successLevel!) / (previousSessions.where((s) => s.successLevel != null).length.clamp(1, 999));

      if (recentAvg > prevAvg + 0.3) {
        trendMessage = 'Practice consistency and success are growing steadily.';
      } else if (recentAvg < prevAvg - 0.3) {
        trendMessage = 'Recent sessions show varied responses; consistency helps progress.';
      } else {
        trendMessage = 'Steady and consistent practice routine maintained.';
      }
    }

    return ProgressSummary(
      totalSessions: totalSessions,
      totalMinutes: totalMinutes,
      domainSummaries: domainSummaries,
      trendMessage: trendMessage,
    );
  }
}
