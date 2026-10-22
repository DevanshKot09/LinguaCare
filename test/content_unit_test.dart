import 'package:flutter_test/flutter_test.dart';
import 'package:linguacare/domain/content/content_item.dart';
import 'package:linguacare/data/repositories/content_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeSupabaseClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #from) {
      throw Exception('offline');
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Content Unit Tests', () {
    test('ContentItem JSON parsing and validation', () {
      final json = {
        'slug': 'test-slug',
        'type': 'article',
        'topic': 'A',
        'title': 'Test Title',
        'summary': 'Test Summary',
        'audience': ['parent', 'teacher'],
        'status': 'published',
        'blocks': [
          {'type': 'paragraph', 'text': 'Hello world'}
        ]
      };

      final item = ContentItem.fromJson(json);
      expect(item.slug, 'test-slug');
      expect(item.title, 'Test Title');
      expect(item.status, ContentStatus.published);
      expect(item.blocks.length, 1);
    });

    test('Release mode shows ZERO bundled items until published', () async {
      final fakeClient = FakeSupabaseClient();
      final repo = ContentRepositoryImpl(fakeClient, isReleaseMode: () => true);
      // Since bundled items under assets/content/v1 are all status: draft, release mode should filter them out (0 items)
      final items = await repo.getContentItems();
      expect(items.isEmpty, true);
    });
  });
}
