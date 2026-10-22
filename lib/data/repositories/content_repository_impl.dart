import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/router/app_session.dart';
import '../../domain/content/content_item.dart';
import '../../domain/content/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepositoryImpl(Supabase.instance.client);
});

final contentListProvider = FutureProvider.family<List<ContentItem>, ({UserRole? role, String? topic, String? query})>((ref, filter) async {
  final repo = ref.watch(contentRepositoryProvider);
  return await repo.getContentItems(role: filter.role, topic: filter.topic, query: filter.query);
});

final contentItemProvider = FutureProvider.family<ContentItem?, String>((ref, slug) async {
  final repo = ref.watch(contentRepositoryProvider);
  return await repo.getContentItemBySlug(slug);
});

final bookmarksProvider = Provider<BookmarksNotifier>((ref) {
  final notifier = BookmarksNotifier(ref.watch(contentRepositoryProvider));
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

final bookmarksStateProvider = Provider<List<String>>((ref) {
  return ref.watch(bookmarksProvider).value;
});

class BookmarksNotifier extends ValueNotifier<List<String>> {
  final ContentRepository _repo;

  BookmarksNotifier(this._repo) : super([]) {
    _load();
  }

  Future<void> _load() async {
    value = await _repo.getBookmarks();
  }

  Future<void> toggle(String slug) async {
    await _repo.toggleBookmark(slug);
    value = await _repo.getBookmarks();
  }
}

class ContentRepositoryImpl implements ContentRepository {
  final SupabaseClient _supabase;
  final bool Function()? _isReleaseMode;
  List<ContentItem>? _cachedItems;

  ContentRepositoryImpl(this._supabase, {bool Function()? isReleaseMode})
      : _isReleaseMode = isReleaseMode;

  bool get _effectiveReleaseMode => _isReleaseMode != null ? _isReleaseMode() : kReleaseMode;

  Future<List<ContentItem>> _loadAllItems() async {
    if (_cachedItems != null) return _cachedItems!;

    Map<String, ContentItem> itemsMap = {};

    try {
      final indexStr = await rootBundle.loadString('assets/content/v1/index.json');
      final indexJson = jsonDecode(indexStr) as Map<String, dynamic>;
      final slugs = List<String>.from(indexJson['slugs'] ?? []);

      for (final slug in slugs) {
        try {
          final itemStr = await rootBundle.loadString('assets/content/v1/items/$slug.json');
          final itemJson = jsonDecode(itemStr) as Map<String, dynamic>;
          final item = ContentItem.fromJson(itemJson);
          itemsMap[item.slug] = item;
        } catch (_) {}
      }
    } catch (_) {}

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/cached_content.json');
      if (await file.exists()) {
        final cachedStr = await file.readAsString();
        final list = (jsonDecode(cachedStr) as List).map((i) => ContentItem.fromJson(i)).toList();
        for (final item in list) {
          if (!itemsMap.containsKey(item.slug) || item.version >= itemsMap[item.slug]!.version) {
            itemsMap[item.slug] = item;
          }
        }
      }
    } catch (_) {}

    try {
      final remoteRes = await _supabase.from('content_items').select('*');
      List<ContentItem> remoteItems = (remoteRes as List).map((i) => ContentItem.fromJson(i)).toList();

      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/cached_content.json');
        await file.writeAsString(jsonEncode(remoteRes));
      } catch (_) {}

      for (final item in remoteItems) {
        if (!itemsMap.containsKey(item.slug) || item.version >= itemsMap[item.slug]!.version) {
          itemsMap[item.slug] = item;
        }
      }
    } catch (_) {}

    _cachedItems = itemsMap.values.toList();
    return _cachedItems!;
  }

  @override
  Future<List<ContentItem>> getContentItems({UserRole? role, String? topic, String? query}) async {
    final all = await _loadAllItems();

    return all.where((item) {
      if (_effectiveReleaseMode && item.status != ContentStatus.published) {
        return false;
      }

      if (role != null && !item.audience.contains(role)) {
        return false;
      }

      if (topic != null && topic.isNotEmpty && item.topic != topic) {
        return false;
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchSummary = item.summary.toLowerCase().contains(q);
        if (!matchTitle && !matchSummary) return false;
      }

      return true;
    }).toList();
  }

  @override
  Future<ContentItem?> getContentItemBySlug(String slug) async {
    final all = await _loadAllItems();
    try {
      return all.firstWhere((i) => i.slug == slug);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('local_bookmarks') ?? [];
  }

  @override
  Future<void> toggleBookmark(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookmarks = prefs.getStringList('local_bookmarks') ?? [];
    if (bookmarks.contains(slug)) {
      bookmarks.remove(slug);
    } else {
      bookmarks.add(slug);
    }
    await prefs.setStringList('local_bookmarks', bookmarks);
  }

  @override
  Future<List<String>> getRecentlyRead() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('recently_read') ?? [];
  }

  @override
  Future<void> addRecentlyRead(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recents = prefs.getStringList('recently_read') ?? [];
    recents.remove(slug);
    recents.insert(0, slug);
    if (recents.length > 10) recents = recents.sublist(0, 10);
    await prefs.setStringList('recently_read', recents);
  }
}
