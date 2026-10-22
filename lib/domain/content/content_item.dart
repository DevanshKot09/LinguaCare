import '../../app/router/app_session.dart';
import '../../domain/profile/profile.dart';
import 'content_block.dart';

enum ContentStatus { draft, slpReview, approved, published }
enum ContentType { article, mythFact, checklist, tipCard }

class ContentSource {
  final String title;
  final String url;
  const ContentSource({required this.title, required this.url});

  factory ContentSource.fromJson(Map<String, dynamic> json) {
    return ContentSource(
      title: json['title'] as String? ?? 'TO BE ADDED BY REVIEWER',
      url: json['url'] as String? ?? '',
    );
  }
}

class ContentItem {
  final String id;
  final String slug;
  final ContentType type;
  final String topic;
  final String title;
  final String summary;
  final List<ContentBlock> blocks;
  final List<UserRole> audience;
  final AgeBand? ageBand;
  final String? goal;
  final String? modifier;
  final String language;
  final int readingMinutes;
  final List<ContentSource> sources;
  final ContentStatus status;
  final String reviewedBy;
  final DateTime? reviewedAt;
  final int version;

  const ContentItem({
    required this.id,
    required this.slug,
    required this.type,
    required this.topic,
    required this.title,
    required this.summary,
    required this.blocks,
    required this.audience,
    this.ageBand,
    this.goal,
    this.modifier,
    required this.language,
    required this.readingMinutes,
    required this.sources,
    required this.status,
    required this.reviewedBy,
    this.reviewedAt,
    required this.version,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    ContentType type = switch (json['type'] as String?) {
      'myth_fact' => ContentType.mythFact,
      'checklist' => ContentType.checklist,
      'tip_card' => ContentType.tipCard,
      _ => ContentType.article,
    };

    ContentStatus status = switch (json['status'] as String?) {
      'slp_review' => ContentStatus.slpReview,
      'approved' => ContentStatus.approved,
      'published' => ContentStatus.published,
      _ => ContentStatus.draft,
    };

    List<UserRole> audience = (json['audience'] as List? ?? []).map((a) {
      return switch (a.toString()) {
        'parent' => UserRole.parent,
        'teacher' => UserRole.teacher,
        'adult' => UserRole.adult,
        'specialist' => UserRole.specialist,
        _ => UserRole.parent,
      };
    }).toList();

    List<ContentBlock> blocks = (json['blocks'] as List? ?? []).map((b) => ContentBlock.fromJson(b)).toList();
    List<ContentSource> sources = (json['sources'] as List? ?? []).map((s) => ContentSource.fromJson(s)).toList();

    return ContentItem(
      id: json['id'] as String? ?? json['slug'] as String? ?? 'unknown',
      slug: json['slug'] as String? ?? '',
      type: type,
      topic: json['topic'] as String? ?? 'A',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      blocks: blocks,
      audience: audience,
      ageBand: json['age_band'] == '11_18' ? AgeBand.band11_18 : (json['age_band'] == '5_11' ? AgeBand.band5_11 : null),
      goal: json['goal'] as String?,
      modifier: json['modifier'] as String?,
      language: json['language'] as String? ?? 'en',
      readingMinutes: json['reading_minutes'] as int? ?? 3,
      sources: sources,
      status: status,
      reviewedBy: json['reviewed_by'] as String? ?? 'TO BE ADDED BY REVIEWER',
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at'] as String) : null,
      version: json['version'] as int? ?? 1,
    );
  }
}
