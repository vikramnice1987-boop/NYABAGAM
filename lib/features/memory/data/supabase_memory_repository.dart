import '../domain/memory_candidate.dart';
import '../domain/memory_models.dart';
import 'memory_repository.dart';
import '../../../core/ai/ai_gateway.dart';

class SupabaseMemoryRepository implements MemoryRepository {
  SupabaseMemoryRepository(this._client);
  final dynamic _client;

  @override
  Future<MemoryModel> confirm(MemoryCandidate candidate) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to save a memory.');
    }

    // 1. Insert Source
    final source = await _client
        .from('memory_sources')
        .insert({
          'user_id': user.id,
          'capture_type': 'text',
          'raw_content': candidate.rawContent,
        })
        .select()
        .single();

    final sourceId = source['id'] as String;

    // 2. Persist People
    for (final person in candidate.people) {
      await _client.from('people').insert({
        'user_id': user.id,
        'name': person,
      }).select().maybeSingle();
    }

    // 3. Persist Things
    for (final thing in candidate.things) {
      await _client.from('things').insert({
        'user_id': user.id,
        'name': thing,
        'current_status': 'active',
      }).select().maybeSingle();
    }

    // 4. Persist Organizations
    for (final org in candidate.organizations) {
      await _client.from('organizations').insert({
        'user_id': user.id,
        'name': org,
      }).select().maybeSingle();
    }

    // 5. Insert Canonical Memory
    final memoryRow = await _client
        .from('memories')
        .insert({
          'user_id': user.id,
          'source_id': sourceId,
          'title': candidate.title,
          'summary': candidate.summary,
          'status': 'confirmed',
          'occurred_at': candidate.occurredAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'metadata': {
            'people': candidate.people,
            'organizations': candidate.organizations,
            'things': candidate.things,
            'places': candidate.places,
            'events': candidate.events,
            'amount': candidate.amount,
            'currency': candidate.currency,
            'raw_content': candidate.rawContent,
            'attachment_base64': candidate.attachmentBase64,
            'attachment_name': candidate.attachmentName,
            'attachment_type': candidate.attachmentType,
            'contact_phone': candidate.contactPhone,
            'warranty_expires_at': candidate.warrantyExpiresAt?.toIso8601String(),
            'service_due_at': candidate.serviceDueAt?.toIso8601String(),
            'machine_type': candidate.machineType,
          },
        })
        .select()
        .single();

    return MemoryModel.fromRow(memoryRow);
  }

  @override
  Future<List<MemoryModel>> confirmed() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('memories')
        .select()
        .eq('user_id', user.id)
        .inFilter('status', ['confirmed', 'active'])
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MemoryModel.fromRow)
        .toList(growable: false);
  }

  @override
  Future<List<MemoryModel>> search(String query) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final rows = await _client.rpc('search_memories', params: {
        'p_query': query,
        'p_limit': 10,
      });

      return (rows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((r) => MemoryModel.fromRow(r))
          .toList();
    } catch (_) {
      // Fallback query
      final rows = await _client
          .from('memories')
          .select()
          .eq('user_id', user.id)
          .ilike('summary', '%$query%')
          .order('created_at', ascending: false)
          .limit(10);

      return (rows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(MemoryModel.fromRow)
          .toList();
    }
  }

  @override
  Future<ContextBridgeResult> findContext(String statement) async {
    final matching = await search(statement);
    final evidence = matching.map((m) => {
      'title': m.title,
      'summary': m.summary,
      'people': m.people,
      'things': m.things,
      'organizations': m.organizations,
      'contact_phone': m.contactPhone,
    }).toList();

    return AiGateway.generateContextBridge(statement, evidence);
  }

  @override
  Future<void> recordOutcome({
    required String thingName,
    required String outcomeSummary,
    required String newStatus,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Update thing status
    await _client
        .from('things')
        .update({'current_status': newStatus})
        .eq('user_id', user.id)
        .ilike('name', '%$thingName%');

    // Create outcome record
    await _client.from('outcomes').insert({
      'user_id': user.id,
      'status': 'resolved',
      'summary': outcomeSummary,
    });

    // Create confirmation memory
    await _client.from('memories').insert({
      'user_id': user.id,
      'title': '$thingName: Repair Resolved',
      'summary': outcomeSummary,
      'status': 'confirmed',
      'metadata': {
        'things': [thingName],
        'status': newStatus,
      },
    });
  }

  @override
  Future<List<MemoryModel>> getExpiringSoon({int daysThreshold = 2}) async {
    final all = await confirmed();
    return all.where((m) => m.isWarrantyExpiringSoon || m.isServiceDueSoon).toList();
  }

  @override
  Future<List<MemoryModel>> getWarrantiesAndReminders() async {
    final all = await confirmed();
    final withReminders = all.where((m) =>
      m.warrantyExpiresAt != null || m.serviceDueAt != null || m.things.isNotEmpty
    ).toList();

    withReminders.sort((a, b) {
      final aDate = a.warrantyExpiresAt ?? a.serviceDueAt ?? a.createdAt;
      final bDate = b.warrantyExpiresAt ?? b.serviceDueAt ?? b.createdAt;
      return aDate.compareTo(bDate);
    });

    return withReminders;
  }

  @override
  Future<void> deleteMemory(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Soft delete memory status
    await _client
        .from('memories')
        .update({'status': 'deleted'})
        .eq('id', id)
        .eq('user_id', user.id);
  }
}