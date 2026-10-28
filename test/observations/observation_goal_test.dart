import 'package:flutter_test/flutter_test.dart';
import 'package:linguacare/domain/observations/observation.dart';
import 'package:linguacare/domain/goals/goal.dart';

bool isValidNote(String note) {
  if (note.length > 500) return false;
  final phoneRegex = RegExp(r'\d{3}[-.\s]?\d{3}[-.\s]?\d{4}');
  final emailRegex = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
  if (phoneRegex.hasMatch(note) || emailRegex.hasMatch(note)) {
    return false;
  }
  return true;
}

bool isValidTags(List<String> tags) {
  return tags.length <= 8;
}

void main() {
  group('Observation & Goal Unit Tests', () {
    test('Note validator detects phone numbers and blocks them', () {
      expect(isValidNote('Hello world'), isTrue);
      expect(isValidNote('Call me at 555-123-4567'), isFalse);
      expect(isValidNote('Phone 5551234567'), isFalse);
    });

    test('Note validator detects email addresses and blocks them', () {
      expect(isValidNote('Great session today.'), isTrue);
      expect(isValidNote('Contact user@test.com for info'), isFalse);
    });

    test('Tag limits enforce maximum of 8 tags', () {
      expect(isValidTags(['a', 'b', 'c']), isTrue);
      expect(isValidTags(List.generate(8, (i) => 'tag$i')), isTrue);
      expect(isValidTags(List.generate(9, (i) => 'tag$i')), isFalse);
    });
  });

  group('Observation & Goal Model Tests', () {
    test('Observation JSON serialization roundtrip and insert payload cleanliness', () {
      final obs = Observation(
        id: 'obs_1',
        childId: 'c_1',
        authorUid: 'p_1',
        tags: ['vocabulary', 'speech'],
        note: 'Good articulation today.',
        setting: 'Home',
        private: false,
        createdAt: DateTime(2026, 3, 1),
      );

      final insertJson = obs.toInsertJson();
      expect(insertJson.containsKey('author_uid'), isFalse);
      expect(insertJson.containsKey('author_role'), isFalse);
      expect(insertJson.containsKey('id'), isFalse);
      expect(insertJson.containsKey('created_at'), isFalse);
      expect(insertJson.containsKey('updated_at'), isFalse);
      expect(insertJson['child_id'], 'c_1');
      expect(insertJson['private'], false);
      expect(insertJson['tags'], ['vocabulary', 'speech']);

      final decoded = Observation.fromJson({
        'id': 'obs_1',
        'child_id': 'c_1',
        'author_uid': 'p_1',
        'tags': ['vocabulary', 'speech'],
        'note': 'Good articulation today.',
        'setting': 'Home',
        'private': false,
        'created_at': '2026-03-01T00:00:00.000Z',
      });
      expect(decoded.note, 'Good articulation today.');
    });

    test('Goal JSON serialization roundtrip and insert payload cleanliness', () {
      final goal = Goal(
        id: 'g_1',
        childId: 'c_1',
        authorUid: 'p_1',
        domain: 'vocabulary',
        description: 'Learn 10 new animal words',
        targetDate: '2026-04-01',
        status: 'active',
        progress: 40,
        createdAt: DateTime(2026, 3, 1),
      );

      final insertJson = goal.toInsertJson();
      expect(insertJson.containsKey('author_uid'), isFalse);
      expect(insertJson.containsKey('author_role'), isFalse);
      expect(insertJson.containsKey('id'), isFalse);
      expect(insertJson.containsKey('created_at'), isFalse);
      expect(insertJson.containsKey('updated_at'), isFalse);
      expect(insertJson['domain'], 'vocabulary');
      expect(insertJson['progress'], 40);

      final decoded = Goal.fromJson({
        'id': 'g_1',
        'child_id': 'c_1',
        'author_uid': 'p_1',
        'domain': 'vocabulary',
        'description': 'Learn 10 new animal words',
        'target_date': '2026-04-01',
        'status': 'active',
        'progress': 40,
        'created_at': '2026-03-01T00:00:00.000Z',
      });
      expect(decoded.description, 'Learn 10 new animal words');
      expect(decoded.progress, 40);
    });

    test('Insert payload has no author fields', () {
      final obs = Observation(
        id: 'obs_1',
        childId: 'c_1',
        authorUid: 'p_1',
        tags: ['speech'],
        note: 'Note',
        private: false,
        createdAt: DateTime.now(),
      );
      final obsInsert = obs.toInsertJson();
      expect(obsInsert.containsKey('author_uid'), isFalse);
      expect(obsInsert.containsKey('author_role'), isFalse);
      expect(obsInsert.containsKey('id'), isFalse);
      expect(obsInsert.containsKey('created_at'), isFalse);
      expect(obsInsert.containsKey('updated_at'), isFalse);

      final goal = Goal(
        id: 'g_1',
        childId: 'c_1',
        authorUid: 'p_1',
        domain: 'vocab',
        description: 'Desc',
        status: 'active',
        progress: 0,
        createdAt: DateTime.now(),
      );
      final goalInsert = goal.toInsertJson();
      expect(goalInsert.containsKey('author_uid'), isFalse);
      expect(goalInsert.containsKey('author_role'), isFalse);
      expect(goalInsert.containsKey('id'), isFalse);
      expect(goalInsert.containsKey('created_at'), isFalse);
      expect(goalInsert.containsKey('updated_at'), isFalse);
    });

    test('Update payload has no author, id or timestamps', () {
      final obs = Observation(
        id: 'obs_1',
        childId: 'c_1',
        authorUid: 'p_1',
        tags: ['speech'],
        note: 'Note',
        private: false,
        createdAt: DateTime.now(),
      );
      final obsUpdate = obs.toUpdateJson();
      expect(obsUpdate.containsKey('author_uid'), isFalse);
      expect(obsUpdate.containsKey('author_role'), isFalse);
      expect(obsUpdate.containsKey('id'), isFalse);
      expect(obsUpdate.containsKey('created_at'), isFalse);
      expect(obsUpdate.containsKey('updated_at'), isFalse);

      final goal = Goal(
        id: 'g_1',
        childId: 'c_1',
        authorUid: 'p_1',
        domain: 'vocab',
        description: 'Desc',
        status: 'active',
        progress: 0,
        createdAt: DateTime.now(),
      );
      final goalUpdate = goal.toUpdateJson();
      expect(goalUpdate.containsKey('author_uid'), isFalse);
      expect(goalUpdate.containsKey('author_role'), isFalse);
      expect(goalUpdate.containsKey('id'), isFalse);
      expect(goalUpdate.containsKey('created_at'), isFalse);
      expect(goalUpdate.containsKey('updated_at'), isFalse);
    });
  });
}
