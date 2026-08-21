import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/memory_candidate.dart';
import '../domain/memory_models.dart';
import '../../../core/ai/ai_gateway.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/supabase/supabase_service.dart';
import 'supabase_memory_repository.dart';

abstract interface class MemoryRepository {
  Future<MemoryModel> confirm(MemoryCandidate candidate);
  Future<List<MemoryModel>> confirmed();
  Future<List<MemoryModel>> search(String query);
  Future<ContextBridgeResult> findContext(String statement);
  Future<void> recordOutcome({
    required String thingName,
    required String outcomeSummary,
    required String newStatus,
  });
  Future<List<MemoryModel>> getExpiringSoon({int daysThreshold = 2});
  Future<List<MemoryModel>> getWarrantiesAndReminders();
  Future<void> deleteMemory(String id);
}

class InMemoryMemoryRepository implements MemoryRepository {
  final List<MemoryModel> _memories = [];
  bool _initialized = false;
  static const _storageKey = 'nyabagam_local_memories';

  Future<void> _ensureLoaded() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        _memories.clear();
        for (final item in raw) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          _memories.add(MemoryModel.fromJson(map));
        }
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _memories.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList(_storageKey, list);
    } catch (_) {}
  }

  @override
  Future<void> deleteMemory(String id) async {
    await _ensureLoaded();
    _memories.removeWhere((m) => m.id == id);
    await _persist();
  }

  @override
  Future<MemoryModel> confirm(MemoryCandidate candidate) async {
    await _ensureLoaded();
    final saved = MemoryModel(
      id: candidate.id,
      title: candidate.title,
      summary: candidate.summary,
      status: 'confirmed',
      createdAt: DateTime.now(),
      occurredAt: candidate.occurredAt ?? DateTime.now(),
      people: candidate.people,
      organizations: candidate.organizations,
      things: candidate.things,
      amount: candidate.amount,
      currency: candidate.currency,
      rawSourceSnippet: candidate.rawContent,
      attachmentBase64: candidate.attachmentBase64,
      attachmentName: candidate.attachmentName,
      attachmentType: candidate.attachmentType,
      contactPhone: candidate.contactPhone,
      warrantyExpiresAt: candidate.warrantyExpiresAt,
      serviceDueAt: candidate.serviceDueAt,
      machineType: candidate.machineType,
    );

    _memories.removeWhere((m) => m.id == saved.id);
    _memories.insert(0, saved);
    await _persist();
    return saved;
  }

  @override
  Future<List<MemoryModel>> confirmed() async {
    await _ensureLoaded();
    return List.unmodifiable(_memories);
  }

  @override
  Future<List<MemoryModel>> search(String query) async {
    await _ensureLoaded();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return confirmed();

    final stopWords = {'who', 'what', 'when', 'where', 'how', 'why', 'did', 'the', 'for', 'my', 'is', 'was', 'in', 'at', 'on', 'to'};
    final tokens = q
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !stopWords.contains(t))
        .toList();

    if (tokens.isEmpty) return confirmed();

    return _memories.where((m) {
      return tokens.any((t) =>
        m.title.toLowerCase().contains(t) ||
        m.summary.toLowerCase().contains(t) ||
        m.people.any((p) => p.toLowerCase().contains(t)) ||
        m.things.any((thing) => thing.toLowerCase().contains(t)) ||
        m.organizations.any((o) => o.toLowerCase().contains(t))
      );
    }).toList();
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
    await _ensureLoaded();
    final title = '$thingName Status Update';
    final memory = MemoryModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      summary: outcomeSummary,
      status: 'confirmed',
      createdAt: DateTime.now(),
      things: [thingName],
    );
    _memories.insert(0, memory);
    await _persist();
  }

  @override
  Future<List<MemoryModel>> getExpiringSoon({int daysThreshold = 2}) async {
    await _ensureLoaded();
    return _memories.where((m) => m.isWarrantyExpiringSoon || m.isServiceDueSoon).toList();
  }

  @override
  Future<List<MemoryModel>> getWarrantiesAndReminders() async {
    await _ensureLoaded();
    final withReminders = _memories.where((m) =>
      m.warrantyExpiresAt != null || m.serviceDueAt != null || m.things.isNotEmpty
    ).toList();

    withReminders.sort((a, b) {
      final aDate = a.warrantyExpiresAt ?? a.serviceDueAt ?? a.createdAt;
      final bDate = b.warrantyExpiresAt ?? b.serviceDueAt ?? b.createdAt;
      return aDate.compareTo(bDate);
    });

    return withReminders;
  }
}

final _localMemoryRepository = InMemoryMemoryRepository();

abstract final class MemoryRepositoryFactory {
  static MemoryRepository get current {
    if (AppEnvironment.current.isSupabaseConfigured &&
        SupabaseService.client.auth.currentUser != null) {
      return SupabaseMemoryRepository(SupabaseService.client);
    }
    return _localMemoryRepository;
  }
}