import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/content_repository_impl.dart';
import '../../domain/content/content_block.dart';
import '../../domain/content/content_item.dart';

class ArticleReaderScreen extends ConsumerStatefulWidget {
  final String slug;

  const ArticleReaderScreen({super.key, required this.slug});

  @override
  ConsumerState<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends ConsumerState<ArticleReaderScreen> {
  double _textScaleFactor = 1.0;

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(contentItemProvider(widget.slug));
    final bookmarks = ref.watch(bookmarksStateProvider);

    return itemAsync.when(
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Article not found.')),
          );
        }

        final isBookmarked = bookmarks.contains(item.slug);

        return Scaffold(
          appBar: AppBar(
            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                onPressed: () {
                  ref.read(bookmarksProvider).toggle(item.slug);
                },
              ),
              PopupMenuButton<double>(
                icon: const Icon(Icons.text_format),
                onSelected: (scale) {
                  setState(() {
                    _textScaleFactor = scale;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 0.9, child: Text('Compact text')),
                  const PopupMenuItem(value: 1.0, child: Text('Normal text')),
                  const PopupMenuItem(value: 1.3, child: Text('Large text')),
                  const PopupMenuItem(value: 1.6, child: Text('Extra large text')),
                ],
              ),
            ],
          ),
          body: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_textScaleFactor)),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (item.status != ContentStatus.published)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Placeholder - not clinically reviewed',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(width: 4),
                    Text('${item.readingMinutes} min read · Topic ${item.topic}', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
                const Divider(height: 32),
                ...item.blocks.map((block) => _buildBlock(context, block)),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Reviewed by: ${item.reviewedBy}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LinguaCare supports language development. It does not diagnose.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Talk to a speech-language professional if you have concerns about communication.',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Specialist directory coming in Phase 4.')),
                          );
                        },
                        child: const Text('Find a Specialist'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (err, st) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildBlock(BuildContext context, ContentBlock block) {
    switch (block) {
      case ParagraphBlock(:final text):
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(text, style: const TextStyle(fontSize: 16, height: 1.5)),
        );
      case HeadingBlock(:final text):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        );
      case BulletsBlock(:final items):
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 16, height: 1.4))),
                ],
              ),
            )).toList(),
          ),
        );
      case StepsBlock(:final items):
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(items[i], style: const TextStyle(fontSize: 16, height: 1.4))),
                    ],
                  ),
                ),
            ],
          ),
        );
      case CalloutBlock(:final text):
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w500)),
        );
      case MythFactBlock(:final myth, :final fact):
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MYTH:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(myth, style: const TextStyle(fontSize: 15)),
                const Divider(height: 24),
                const Text('FACT:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(fact, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      case BarrierFixBlock(:final barriers):
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: barriers.map((b) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Barrier: ${b.barrier}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const SizedBox(height: 4),
                    Text('Fix: ${b.fix}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            )).toList(),
          ),
        );
      case RoleTabsBlock(:final tabs):
        return DefaultTabController(
          length: tabs.length,
          child: Column(
            children: [
              TabBar(
                tabs: tabs.keys.map((k) => Tab(text: k.toUpperCase())).toList(),
                labelColor: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(
                height: 120,
                child: TabBarView(
                  children: tabs.values.map((v) => Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(v, style: const TextStyle(fontSize: 15)),
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      case DisclaimerBlock(:final text):
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(text, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.outline)),
        );
    }
  }
}
