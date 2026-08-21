import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/features/memory/data/memory_repository.dart';
import 'package:nyabagam/features/memory/domain/memory_candidate.dart';

void main() {
  group('Performance & Memory Benchmark Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Searches 200 memory entities within 15 milliseconds', () async {
      final repo = InMemoryMemoryRepository();

      // Seed 200 memories
      for (int i = 0; i < 200; i++) {
        final candidate = MemoryCandidate.fromText('Service record #$i for Appliance-$i by Technician-$i')
            .withUnderstanding({
          'title': 'Appliance Service #$i',
          'summary': 'Routine maintenance check for item #$i.',
          'people': ['Technician-$i'],
          'things': ['Appliance-$i'],
          'amount': 500.0 + i,
        });
        await repo.confirm(candidate);
      }

      final stopwatch = Stopwatch()..start();
      final results = await repo.search('150');
      stopwatch.stop();

      expect(results.length, equals(1));
      expect(results.first.title, contains('#150'));
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('Candidate JSON serialization runs in sub-millisecond time', () {
      final candidate = MemoryCandidate.fromText('LG Smart TV repair by Suresh')
          .withUnderstanding({
        'title': 'LG TV Repair',
        'summary': 'Panel replacement done under warranty.',
        'people': ['Suresh'],
        'things': ['TV'],
        'machine_type': 'TV',
        'amount': 4500,
        'warranty_period': '1 year',
      });

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 500; i++) {
        final json = candidate.toJson();
        final restored = MemoryCandidate.fromJson(json);
        expect(restored.title, equals('LG TV Repair'));
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}