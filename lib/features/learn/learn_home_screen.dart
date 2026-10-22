import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_session.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../domain/content/content_item.dart';
import 'article_reader_screen.dart';
import '../tools/tools_hub_screen.dart';

class LearnHomeScreen extends ConsumerStatefulWidget {
  const LearnHomeScreen({super.key});

  @override
  ConsumerState<LearnHomeScreen> createState() => _LearnHomeScreenState();
}

class _LearnHomeScreenState extends ConsumerState<LearnHomeScreen> {
  String? _selectedTopic;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<Map<String, String>> _topics = [
    {'code': 'A', 'label': 'What is DLD'},
    {'code': 'B', 'label': 'Early Signs'},
    {'code': 'C', 'label': 'Assessment'},
    {'code': 'D', 'label': 'Myths & Facts'},
    {'code': 'E', 'label': 'Impact'},
    {'code': 'F', 'label': 'Classroom'},
    {'code': 'G', 'label': 'Therapy'},
    {'code': 'H', 'label': 'At Home'},
    {'code': 'I', 'label': 'Design'},
    {'code': 'J', 'label': 'Ethics'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionStateProvider);
    final role = session.role;
    final bookmarks = ref.watch(bookmarksStateProvider);

    final contentAsync = ref.watch(contentListProvider((role: role, topic: _selectedTopic, query: _searchQuery)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: ListTile(
                  leading: const Icon(Icons.build_rounded),
                  title: const Text('LinguaCare Tools Section', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Schedules, Instruction Simplifier & Comm Cards'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ToolsHubScreen()),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search articles, tips, myths...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _topics.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All Topics'),
                        selected: _selectedTopic == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTopic = null;
                          });
                        },
                      ),
                    );
                  }
                  final topic = _topics[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(topic['label']!),
                      selected: _selectedTopic == topic['code'],
                      onSelected: (selected) {
                        setState(() {
                          _selectedTopic = selected ? topic['code'] : null;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: contentAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No articles found matching your query.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isBookmarked = bookmarks.contains(item.slug);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                              if (item.status == ContentStatus.draft)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Draft', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.outline),
                                  const SizedBox(width: 4),
                                  Text('${item.readingMinutes} min read', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Theme.of(context).colorScheme.primary),
                            onPressed: () {
                              ref.read(bookmarksProvider).toggle(item.slug);
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ArticleReaderScreen(slug: item.slug)),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Error loading content: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
