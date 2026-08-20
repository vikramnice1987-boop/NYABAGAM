import '../../features/memory/domain/memory_candidate.dart';
import '../../features/memory/domain/memory_models.dart';
import '../config/app_environment.dart';
import '../supabase/supabase_service.dart';

/// Mobile-safe AI Gateway communicating with the server-side AI Orchestrator Edge Function.
abstract final class AiGateway {
  static Future<MemoryCandidate> understand(String content) async {
    final candidate = MemoryCandidate.fromText(content);
    if (!AppEnvironment.current.isSupabaseConfigured) {
      return _localUnderstand(content, candidate);
    }

    try {
      final response = await SupabaseService.client.functions.invoke(
        AppEnvironment.current.aiFunctionName,
        body: {
          'operation': 'understand',
          'content': content,
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      if (data.containsKey('result')) {
        return candidate.withUnderstanding(Map<String, dynamic>.from(data['result'] as Map));
      }
      return candidate;
    } catch (_) {
      return _localUnderstand(content, candidate);
    }
  }

  static Future<AskResult> ask(String query, List<Map<String, dynamic>> evidence) async {
    if (!AppEnvironment.current.isSupabaseConfigured) {
      return _localAsk(query, evidence);
    }

    try {
      final response = await SupabaseService.client.functions.invoke(
        AppEnvironment.current.aiFunctionName,
        body: {
          'operation': 'ask',
          'query': query,
          'evidence': evidence,
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      if (data.containsKey('result')) {
        return AskResult.fromJson(Map<String, dynamic>.from(data['result'] as Map));
      }
      return _localAsk(query, evidence);
    } catch (_) {
      return _localAsk(query, evidence);
    }
  }

  static Future<ContextBridgeResult> generateContextBridge(
    String statement,
    List<Map<String, dynamic>> evidence,
  ) async {
    if (!AppEnvironment.current.isSupabaseConfigured) {
      return _localContextBridge(statement, evidence);
    }

    try {
      final response = await SupabaseService.client.functions.invoke(
        AppEnvironment.current.aiFunctionName,
        body: {
          'operation': 'context',
          'statement': statement,
          'evidence': evidence,
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      if (data.containsKey('result')) {
        return ContextBridgeResult.fromJson(Map<String, dynamic>.from(data['result'] as Map));
      }
      return _localContextBridge(statement, evidence);
    } catch (_) {
      return _localContextBridge(statement, evidence);
    }
  }

  // --- Local Fallbacks (for offline or demo mode) ---
  static MemoryCandidate _localUnderstand(String content, MemoryCandidate base) {
    final lower = content.toLowerCase();
    final people = <String>[];
    final things = <String>[];
    final orgs = <String>[];
    final events = <String>[];
    double? amount;
    final relationships = <DetectedRelationship>[];

    // Generic heuristic extraction for offline fallback
    if (lower.contains('ravi')) people.add('Ravi');
    if (lower.contains('ac') || lower.contains('air conditioner')) things.add('AC');
    if (lower.contains('coolcare') || lower.contains('cool care')) orgs.add('CoolCare');
    if (lower.contains('service') || lower.contains('serviced')) events.add('Service');
    if (lower.contains('purchase') || lower.contains('bought')) events.add('Purchase');
    if (lower.contains('repair') || lower.contains('fixed')) events.add('Repair');

    final reg = RegExp(r'[₹$]?\s*(\d+(\.\d+)?)');
    final match = reg.firstMatch(content);
    if (match != null) {
      amount = double.tryParse(match.group(1)!);
    }

    if (people.isNotEmpty && things.isNotEmpty) {
      relationships.add(DetectedRelationship(source: people.first, relationship: 'serviced', target: things.first));
    }
    if (people.isNotEmpty && orgs.isNotEmpty) {
      relationships.add(DetectedRelationship(source: people.first, relationship: 'works_for', target: orgs.first));
    }

    return base.copyWith(
      title: things.isNotEmpty && events.isNotEmpty ? '${things.first} ${events.first}' : 'Memory candidate',
      summary: content,
      people: people,
      organizations: orgs,
      things: things,
      events: events,
      relationships: relationships,
      amount: amount,
      currency: amount != null ? 'INR' : null,
    );
  }

  static AskResult _localAsk(String query, List<Map<String, dynamic>> evidence) {
    if (evidence.isEmpty) {
      return const AskResult(
        answer: "I couldn't find any memories matching your question.",
        confidence: 'no_evidence',
      );
    }

    final top = evidence.first;
    final title = top['title'] ?? '';
    final summary = top['summary'] ?? '';
    return AskResult(
      answer: '$title: $summary',
      confidence: 'high',
      relatedEntities: List<String>.from(top['people'] ?? []),
      suggestedActions: [
        if ((top['people'] as List? ?? []).isNotEmpty)
          ActionProposal(
            actionType: 'message',
            title: 'Contact ${top['people'][0]}',
            channel: 'whatsapp',
            recipientName: top['people'][0],
          ),
      ],
    );
  }

  static ContextBridgeResult _localContextBridge(String statement, List<Map<String, dynamic>> evidence) {
    final hasPast = evidence.isNotEmpty;
    final past = hasPast ? evidence.first : <String, dynamic>{};
    final person = (past['people'] as List? ?? []).isNotEmpty ? past['people'][0] as String : 'the technician';
    final thing = (past['things'] as List? ?? []).isNotEmpty ? past['things'][0] as String : 'your appliance';

    return ContextBridgeResult(
      detectedProblem: statement,
      relevantMemorySummary: hasPast ? (past['summary'] as String? ?? 'Past service recorded.') : 'No previous service found.',
      whyRelevant: hasPast ? 'You previously had $thing serviced by $person.' : 'You can log a new service or find assistance.',
      targetPerson: hasPast ? person : null,
      suggestedActions: [
        if (hasPast)
          ActionProposal(
            actionType: 'message',
            title: 'Contact $person on WhatsApp',
            channel: 'whatsapp',
            recipientName: person,
            draftMessage: 'Hi $person, my $thing is not working properly again. Could you please take a look?',
          ),
        ActionProposal(
          actionType: 'manual',
          title: 'View $thing History',
          channel: 'none',
        ),
      ],
    );
  }
}