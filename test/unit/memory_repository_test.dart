import 'package:flutter_test/flutter_test.dart';
import 'package:nyabagam/features/memory/data/memory_repository.dart';
import 'package:nyabagam/features/memory/domain/memory_candidate.dart';

void main() {
  group('MemoryRepository Logic', () {
    late InMemoryMemoryRepository repo;

    setUp(() {
      repo = InMemoryMemoryRepository();
    });

    test('confirms and retrieves memory', () async {
      final candidate = MemoryCandidate.fromText('Ravi serviced my AC today for Rs. 800.').withUnderstanding({
        'title': 'AC Service by Ravi',
        'summary': 'Ravi serviced the AC for Rs. 800.',
        'people': ['Ravi'],
        'things': ['AC'],
        'amount': 800,
      });

      final saved = await repo.confirm(candidate);
      expect(saved.title, equals('AC Service by Ravi'));

      final all = await repo.confirmed();
      expect(all.length, equals(1));
      expect(all.first.people, contains('Ravi'));
      expect(all.first.things, contains('AC'));
    });

    test('searches memories by entity keyword', () async {
      final candidate = MemoryCandidate.fromText('Ravi serviced my AC').withUnderstanding({
        'title': 'AC Service',
        'summary': 'Ravi serviced the AC.',
        'people': ['Ravi'],
        'things': ['AC'],
      });
      await repo.confirm(candidate);

      final searchAC = await repo.search('AC');
      expect(searchAC.length, equals(1));

      final searchRavi = await repo.search('Ravi');
      expect(searchRavi.length, equals(1));

      final searchNotFound = await repo.search('Refrigerator');
      expect(searchNotFound.isEmpty, isTrue);
    });

    test('records outcome and updates memory state', () async {
      await repo.recordOutcome(
        thingName: 'AC',
        outcomeSummary: 'Ravi fixed the AC capacitor.',
        newStatus: 'active',
      );

      final memories = await repo.confirmed();
      expect(memories.any((m) => m.summary.contains('Ravi fixed the AC capacitor')), isTrue);
    });
  });
}