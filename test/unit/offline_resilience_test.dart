import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/core/ai/ai_gateway.dart';
import 'package:nyabagam/features/memory/data/memory_repository.dart';
import 'package:nyabagam/features/memory/domain/memory_candidate.dart';

void main() {
  group('Offline Resilience & Local Sync Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('AiGateway heuristic engine processes offline inputs without network', () async {
      final candidate = await AiGateway.understand(
        'Dr. Rajesh clinic visit follow up on Aug 25 for fever consultation fee Rs. 500.',
      );

      expect(candidate.title, contains('Rajesh'));
      expect(candidate.people, contains('Rajesh'));
      expect(candidate.amount, equals(500));
      expect(candidate.summary, isNotEmpty);
    });

    test('AiGateway offline extracts 2-day warranty expiration from voice text', () async {
      final candidate = await AiGateway.understand(
        'LG Refrigerator compressor checked by Suresh. Warranty expires in 2 days.',
      );

      expect(candidate.machineType, equals('Refrigerator'));
      expect(candidate.warrantyExpiresAt, isNotNull);
      expect(candidate.people, contains('Suresh'));
    });

    test('InMemoryMemoryRepository persists and restores across cold reload', () async {
      // Step 1: Initial cold run - save memory
      final repo1 = InMemoryMemoryRepository();
      final candidate = MemoryCandidate.fromText('Purchased Dell laptop with 1 year warranty').withUnderstanding({
        'title': 'Dell Laptop Purchase',
        'summary': 'Purchased Dell laptop with warranty.',
        'things': ['Laptop'],
        'machine_type': 'Laptop',
      });
      await repo1.confirm(candidate);
      expect((await repo1.confirmed()).length, equals(1));

      // Step 2: Simulate app restart / new repository instance reading from same SharedPreferences
      final repo2 = InMemoryMemoryRepository();
      final restored = await repo2.confirmed();
      expect(restored.length, equals(1));
      expect(restored.first.title, equals('Dell Laptop Purchase'));
      expect(restored.first.things, contains('Laptop'));
    });

    test('InMemoryMemoryRepository handles corrupted local storage gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('nyabagam_local_memories', ['{invalid_json']);

      final repo = InMemoryMemoryRepository();
      final memories = await repo.confirmed();
      expect(memories.isEmpty, isTrue); // Gracefully returns empty without crashing
    });
  });
}