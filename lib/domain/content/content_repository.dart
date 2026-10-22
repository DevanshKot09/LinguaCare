import '../../app/router/app_session.dart';
import 'content_item.dart';

abstract class ContentRepository {
  Future<List<ContentItem>> getContentItems({UserRole? role, String? topic, String? query});
  Future<ContentItem?> getContentItemBySlug(String slug);
  Future<List<String>> getBookmarks();
  Future<void> toggleBookmark(String slug);
  Future<List<String>> getRecentlyRead();
  Future<void> addRecentlyRead(String slug);
}
