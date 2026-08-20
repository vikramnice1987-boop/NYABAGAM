import '../../features/memory/domain/memory_candidate.dart';
import '../../features/memory/domain/memory_models.dart';
import '../config/app_environment.dart';
import '../supabase/supabase_service.dart';

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
      return _localUnderstand(content, candidate);
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

  // --- Intelligent Local Understanding Engine (General-Purpose Extraction) ---
  static MemoryCandidate _localUnderstand(String content, MemoryCandidate base) {
    final lower = content.toLowerCase();
    final words = content.split(RegExp(r'\s+'));
    final people = <String>{};
    final things = <String>{};
    final orgs = <String>{};
    final events = <String>{};
    double? amount;
    final relationships = <DetectedRelationship>[];

    // 1. Amount Extraction
    final amtRegex = RegExp(r'(?:[₹$€£]|rs\.?|inr|usd)\s*([\d,]+(?:\.\d+)?)', caseSensitive: false);
    final amtMatch = amtRegex.firstMatch(content);
    if (amtMatch != null) {
      final rawNum = amtMatch.group(1)?.replaceAll(',', '');
      if (rawNum != null) amount = double.tryParse(rawNum);
    } else {
      final plainNumRegex = RegExp(r'\b(?:for|paid|cost|price|fee|worth)\s*(?:of)?\s*([\d,]+(?:\.\d+)?)\b', caseSensitive: false);
      final plainMatch = plainNumRegex.firstMatch(content);
      if (plainMatch != null) {
        final rawNum = plainMatch.group(1)?.replaceAll(',', '');
        if (rawNum != null) amount = double.tryParse(rawNum);
      }
    }

    // 2. Common Things / Appliances / Items
    final knownThings = {
      'ac': 'AC', 'air conditioner': 'Air Conditioner', 'car': 'Car', 'bike': 'Bike',
      'laptop': 'Laptop', 'phone': 'Phone', 'fridge': 'Refrigerator', 'refrigerator': 'Refrigerator',
      'tv': 'Television', 'television': 'Television', 'washing machine': 'Washing Machine',
      'geyser': 'Geyser', 'inverter': 'Inverter', 'motor': 'Water Motor', 'water purifier': 'Water Purifier',
      'ro': 'RO Purifier', 'wifi': 'WiFi Router', 'router': 'Router', 'scooter': 'Scooter',
      'fan': 'Ceiling Fan', 'tablet': 'Tablet', 'watch': 'Smartwatch', 'sofa': 'Sofa',
    };
    for (final entry in knownThings.entries) {
      if (lower.contains(entry.key)) things.add(entry.value);
    }

    // 3. Known Organizations & Stores
    final knownOrgs = {
      'coolcare': 'CoolCare', 'samsung': 'Samsung', 'lg': 'LG', 'sony': 'Sony',
      'apple': 'Apple', 'amazon': 'Amazon', 'flipkart': 'Flipkart', 'honda': 'Honda',
      'tata': 'Tata', 'maruti': 'Maruti Suzuki', 'hyundai': 'Hyundai', 'apollo': 'Apollo Clinic',
      'urban company': 'Urban Company', 'croma': 'Croma', 'reliance digital': 'Reliance Digital',
    };
    for (final entry in knownOrgs.entries) {
      if (lower.contains(entry.key)) orgs.add(entry.value);
    }

    // 4. Extract Proper Nouns / Names following keywords (by, to, from, with, doctor, dr, mr, technician, mechanic, plumber)
    final nameKeywords = {'by', 'to', 'from', 'with', 'doctor', 'dr.', 'dr', 'mr.', 'mr', 'mrs', 'technician', 'mechanic', 'plumber', 'electrician', 'carpenter', 'driver'};
    for (var i = 0; i < words.length; i++) {
      final cleanWord = words[i].replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
      if (nameKeywords.contains(cleanWord) && i + 1 < words.length) {
        final nextWord = words[i + 1].replaceAll(RegExp(r'[^\w]'), '');
        if (nextWord.isNotEmpty && nextWord[0] == nextWord[0].toUpperCase() && !knownThings.containsKey(nextWord.toLowerCase())) {
          people.add(nextWord);
        }
      }
    }
    // Also check first word if capitalized and followed by a verb (e.g. "Ravi serviced...", "Suresh fixed...")
    if (words.isNotEmpty) {
      final first = words[0].replaceAll(RegExp(r'[^\w]'), '');
      if (first.isNotEmpty && first[0] == first[0].toUpperCase() && first.length > 2 && !knownThings.containsKey(first.toLowerCase())) {
        final commonStopWords = {'my', 'the', 'yesterday', 'today', 'last', 'i', 'we', 'this', 'our', 'new'};
        if (!commonStopWords.contains(first.toLowerCase())) {
          people.add(first);
        }
      }
    }

    // 5. Events / Actions
    if (lower.contains('service') || lower.contains('serviced')) events.add('Service');
    if (lower.contains('repair') || lower.contains('fixed') || lower.contains('repaired')) events.add('Repair');
    if (lower.contains('purchase') || lower.contains('bought') || lower.contains('buy')) events.add('Purchase');
    if (lower.contains('doctor') || lower.contains('prescription') || lower.contains('consultation') || lower.contains('clinic')) events.add('Medical');
    if (lower.contains('warranty') || lower.contains('guarantee')) events.add('Warranty');
    if (lower.contains('insurance') || lower.contains('policy')) events.add('Insurance');
    if (lower.contains('rent') || lower.contains('deposit')) events.add('Rent');

    // Title formulation
    String title;
    if (things.isNotEmpty && events.isNotEmpty) {
      title = '${things.first} ${events.first}';
    } else if (people.isNotEmpty && events.isNotEmpty) {
      title = '${events.first} with ${people.first}';
    } else if (things.isNotEmpty) {
      title = '${things.first} Record';
    } else if (events.isNotEmpty) {
      title = '${events.first} Note';
    } else {
      title = content.length > 30 ? '${content.substring(0, 27)}...' : content;
      if (title.isEmpty) title = 'New Memory';
    }

    return base.copyWith(
      title: title,
      summary: content,
      people: people.toList(),
      organizations: orgs.toList(),
      things: things.toList(),
      events: events.toList(),
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
    final people = List<String>.from(top['people'] ?? []);
    return AskResult(
      answer: '$title: $summary',
      confidence: 'high',
      relatedEntities: people,
      suggestedActions: [
        if (people.isNotEmpty)
          ActionProposal(
            actionType: 'message',
            title: 'Contact ${people[0]} on WhatsApp',
            channel: 'whatsapp',
            recipientName: people[0],
          ),
      ],
    );
  }

  static ContextBridgeResult _localContextBridge(String statement, List<Map<String, dynamic>> evidence) {
    final hasPast = evidence.isNotEmpty;
    final past = hasPast ? evidence.first : <String, dynamic>{};
    final person = (past['people'] as List? ?? []).isNotEmpty ? past['people'][0] as String : 'the service technician';
    final thing = (past['things'] as List? ?? []).isNotEmpty ? past['things'][0] as String : 'appliance';

    return ContextBridgeResult(
      detectedProblem: statement,
      relevantMemorySummary: hasPast ? (past['summary'] as String? ?? 'Past memory located.') : 'No previous records found.',
      whyRelevant: hasPast ? 'Found past records related to $thing.' : 'You can log a new record or action.',
      targetPerson: hasPast ? person : null,
      suggestedActions: [
        if (hasPast)
          ActionProposal(
            actionType: 'message',
            title: 'Contact $person on WhatsApp',
            channel: 'whatsapp',
            recipientName: person,
            draftMessage: 'Hi $person, regarding my $thing, could you please check it?',
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