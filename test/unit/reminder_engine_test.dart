import 'package:flutter_test/flutter_test.dart';
import 'package:nyabagam/core/ai/ai_gateway.dart';
import 'package:nyabagam/features/memory/domain/memory_models.dart';
import 'package:nyabagam/features/memory/data/memory_repository.dart';

void main() {
  group('Machine Warranty & 2-Day Proactive Reminder Engine Tests', () {
    late InMemoryMemoryRepository repo;

    setUp(() {
      repo = InMemoryMemoryRepository();
    });

    test('AiGateway extracts warranty period (6 months) and machine type (AC)', () async {
      final candidate = await AiGateway.understand('Ravi serviced my AC today, gave 6 months warranty. Contact 9840012345');

      expect(candidate.things, contains('AC'));
      expect(candidate.machineType, equals('AC'));
      expect(candidate.warrantyExpiresAt, isNotNull);
      expect(candidate.contactPhone, equals('9840012345'));

      // Check warranty expiration calculation is approx ~180 days in future
      final diff = candidate.warrantyExpiresAt!.difference(DateTime.now()).inDays;
      expect(diff, greaterThanOrEqualTo(178));
      expect(diff, lessThanOrEqualTo(182));
    });

    test('AiGateway extracts 2-day warranty alert correctly', () async {
      final candidate = await AiGateway.understand('LG Washing Machine warranty expires in 2 days');

      expect(candidate.things, contains('Washing Machine'));
      expect(candidate.machineType, equals('Washing Machine'));
      expect(candidate.warrantyExpiresAt, isNotNull);

      final model = MemoryModel(
        id: candidate.id,
        title: candidate.title,
        summary: candidate.summary,
        status: 'confirmed',
        createdAt: candidate.capturedAt,
        warrantyExpiresAt: candidate.warrantyExpiresAt,
      );
      expect(model.isWarrantyExpiringSoon, isTrue);
      expect(model.warrantyDaysRemaining, equals(2));
    });

    test('MemoryModel accurately calculates 2-day expiration flag', () {
      final modelExpiringSoon = MemoryModel(
        id: 'test_1',
        title: 'Samsung AC Service',
        summary: 'AC serviced with 2 day warranty left',
        status: 'confirmed',
        createdAt: DateTime.now(),
        warrantyExpiresAt: DateTime.now().add(const Duration(days: 2)),
        machineType: 'AC',
      );

      expect(modelExpiringSoon.isWarrantyExpiringSoon, isTrue);
      expect(modelExpiringSoon.isExpired, isFalse);
      expect(modelExpiringSoon.warrantyDaysRemaining, equals(2));

      final modelSafe = MemoryModel(
        id: 'test_2',
        title: 'Honda Bike Warranty',
        summary: '1 year warranty on battery',
        status: 'confirmed',
        createdAt: DateTime.now(),
        warrantyExpiresAt: DateTime.now().add(const Duration(days: 365)),
        machineType: 'Bike',
      );

      expect(modelSafe.isWarrantyExpiringSoon, isFalse);
      expect(modelSafe.warrantyDaysRemaining, equals(365));
    });

    test('Repository filters urgent memories with getExpiringSoon', () async {
      final candidateUrgent = await AiGateway.understand('Water Purifier service due in 2 days');
      final candidateNormal = await AiGateway.understand('Laptop purchase 1 year warranty');

      await repo.confirm(candidateUrgent);
      await repo.confirm(candidateNormal);

      final urgent = await repo.getExpiringSoon(daysThreshold: 2);
      expect(urgent.length, equals(1));
      expect(urgent.first.title, contains('Water Purifier'));
    });
  });
}