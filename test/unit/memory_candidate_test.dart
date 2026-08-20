import 'package:flutter_test/flutter_test.dart';
import 'package:nyabagam/features/memory/domain/memory_candidate.dart';

void main() {
  group('MemoryCandidate Domain Logic', () {
    test('creates candidate from raw text correctly', () {
      final candidate = MemoryCandidate.fromText('Ravi serviced my AC today for ₹800.');
      expect(candidate.rawContent, equals('Ravi serviced my AC today for ₹800.'));
      expect(candidate.status, equals(MemoryStatus.candidate));
      expect(candidate.id, isNotEmpty);
      expect(candidate.sourceId, isNotEmpty);
    });

    test('updates candidate with structured understanding', () {
      final candidate = MemoryCandidate.fromText('Ravi serviced my AC today for ₹800.').withUnderstanding({
        'title': 'AC Service by Ravi',
        'summary': 'Ravi from CoolCare serviced the AC for ₹800.',
        'people': ['Ravi'],
        'organizations': ['CoolCare'],
        'things': ['AC'],
        'events': ['Service'],
        'amount': 800,
        'currency': 'INR',
      });

      expect(candidate.title, equals('AC Service by Ravi'));
      expect(candidate.people, contains('Ravi'));
      expect(candidate.organizations, contains('CoolCare'));
      expect(candidate.things, contains('AC'));
      expect(candidate.amount, equals(800.0));
      expect(candidate.currency, equals('INR'));
    });

    test('confirms candidate status transition', () {
      final candidate = MemoryCandidate.fromText('Test memory');
      final confirmed = candidate.confirm();
      expect(confirmed.status, equals(MemoryStatus.confirmed));
    });
  });
}