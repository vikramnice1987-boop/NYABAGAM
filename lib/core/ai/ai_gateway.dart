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

  // --- Multi-Language & Multi-Entity Offline Understanding Engine ---
    static String _cleanText(String input) {
    final words = input.split(RegExp(r'\s+'));
    final unique = <String>[];
    for (final w in words) {
      final trimmed = w.trim();
      if (trimmed.isEmpty) continue;
      if (unique.isEmpty || unique.last.toLowerCase() != trimmed.toLowerCase()) {
        unique.add(trimmed);
      }
    }
    return unique.join(' ');
  }

  static MemoryCandidate _localUnderstand(String rawInput, MemoryCandidate base) {
    final content = _cleanText(rawInput);
    final lower = content.toLowerCase();
    final words = content.split(RegExp(r'\s+'));
    final people = <String>{};
    final things = <String>{};
    final orgs = <String>{};
    final events = <String>{};
    double? amount;
    String? detectedPhone;
    final relationships = <DetectedRelationship>[];

    // 1. Phone / WhatsApp Number Extraction (e.g. +91 9876543210, 9876543210)
    final phoneRegex = RegExp(r'(?:\+?91[\-\s]?)?[6-9]\d{9}\b');
    final phoneMatch = phoneRegex.firstMatch(content);
    if (phoneMatch != null) {
      detectedPhone = phoneMatch.group(0)?.replaceAll(RegExp(r'[\-\s]'), '');
    }

    // 2. Amount Extraction (â‚¹, $, Rs, INR, à®°à¯‚à®ªà®¾à®¯à¯)
    final amtRegex = RegExp(r'(?:[â‚¹$â‚¬Â£]|rs\.?|inr|à®°à¯‚à®ªà®¾à®¯à¯|à®°à¯‚\.?)\s*([\d,]+(?:\.\d+)?)', caseSensitive: false);
    final amtMatch = amtRegex.firstMatch(content);
    if (amtMatch != null) {
      final rawNum = amtMatch.group(1)?.replaceAll(',', '');
      if (rawNum != null) amount = double.tryParse(rawNum);
    } else {
      final plainNumRegex = RegExp(r'\b(?:for|paid|cost|price|fee|worth|à®šà¯†à®²à®µà¯|à®•à¯Šà®Ÿà¯à®¤à¯à®¤à¯‡à®©à¯)\s*(?:of)?\s*([\d,]+(?:\.\d+)?)\b', caseSensitive: false);
      final plainMatch = plainNumRegex.firstMatch(content);
      if (plainMatch != null) {
        final rawNum = plainMatch.group(1)?.replaceAll(',', '');
        if (rawNum != null) amount = double.tryParse(rawNum);
      }
    }

    // 3. Multi-language Things / Appliances / Items (English & Tamil)
    final knownThings = {
      'ac': 'AC', 'air conditioner': 'Air Conditioner', 'à®à®šà®¿': 'AC',
      'car': 'Car', 'à®•à®¾à®°à¯': 'Car',
      'bike': 'Bike', 'à®ªà¯ˆà®•à¯': 'Bike', 'à®µà®£à¯à®Ÿà®¿': 'Two Wheeler',
      'laptop': 'Laptop', 'à®²à¯‡à®ªà¯à®Ÿà®¾à®ªà¯': 'Laptop',
      'phone': 'Phone', 'à®ªà¯‹à®©à¯': 'Phone', 'à®®à¯Šà®ªà¯ˆà®²à¯': 'Mobile Phone',
      'fridge': 'Refrigerator', 'refrigerator': 'Refrigerator', 'à®ªà®¿à®°à®¿à®Ÿà¯à®œà¯': 'Refrigerator',
      'tv': 'Television', 'television': 'Television', 'à®Ÿà®¿à®µà®¿': 'Television',
      'washing machine': 'Washing Machine', 'à®µà®¾à®·à®¿à®™à¯ à®®à¯†à®·à®¿à®©à¯': 'Washing Machine',
      'geyser': 'Geyser', 'à®•à¯€à®šà®°à¯': 'Geyser',
      'inverter': 'Inverter', 'à®‡à®©à¯à®µà¯†à®°à¯à®Ÿà¯à®Ÿà®°à¯': 'Inverter',
      'motor': 'Water Motor', 'à®®à¯‹à®Ÿà¯à®Ÿà®¾à®°à¯': 'Water Motor',
      'water purifier': 'Water Purifier', 'ro': 'RO Purifier',
      'fan': 'Ceiling Fan', 'à®ƒà®ªà¯‡à®©à¯': 'Fan',
    };
    for (final entry in knownThings.entries) {
      if (lower.contains(entry.key)) things.add(entry.value);
    }

    // 4. Multi-language Organizations & Stores
    final knownOrgs = {
      'coolcare': 'CoolCare', 'samsung': 'Samsung', 'à®šà®¾à®®à¯à®šà®™à¯': 'Samsung',
      'lg': 'LG', 'à®Žà®²à¯à®œà®¿': 'LG', 'sony': 'Sony', 'à®šà¯‹à®©à®¿': 'Sony',
      'apple': 'Apple', 'amazon': 'Amazon', 'flipkart': 'Flipkart',
      'honda': 'Honda', 'à®¹à¯‹à®£à¯à®Ÿà®¾': 'Honda', 'tata': 'Tata', 'à®Ÿà®¾à®Ÿà®¾': 'Tata',
      'apollo': 'Apollo Clinic', 'à®…à®ªà¯à®ªà¯‹à®²à¯‹': 'Apollo',
      'urban company': 'Urban Company', 'croma': 'Croma',
    };
    for (final entry in knownOrgs.entries) {
      if (lower.contains(entry.key)) orgs.add(entry.value);
    }

    // 5. Extract Names following keywords
    final nameKeywords = {'by', 'to', 'from', 'with', 'doctor', 'dr.', 'dr', 'mr.', 'mr', 'mrs', 'technician', 'mechanic', 'plumber', 'electrician'};
    for (var i = 0; i < words.length; i++) {
      final cleanWord = words[i].replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
      if (nameKeywords.contains(cleanWord) && i + 1 < words.length) {
        final nextWord = words[i + 1].replaceAll(RegExp(r'[^\w]'), '');
        if (nextWord.isNotEmpty && nextWord[0] == nextWord[0].toUpperCase() && !knownThings.containsKey(nextWord.toLowerCase())) {
          people.add(nextWord);
        }
      }
    }
    // Also check first word if capitalized
    if (words.isNotEmpty) {
      final first = words[0].replaceAll(RegExp(r'[^\w]'), '');
      if (first.isNotEmpty && first[0] == first[0].toUpperCase() && first.length > 2 && !knownThings.containsKey(first.toLowerCase())) {
        final commonStopWords = {'my', 'the', 'yesterday', 'today', 'last', 'i', 'we', 'this', 'our', 'new'};
        if (!commonStopWords.contains(first.toLowerCase())) {
          people.add(first);
        }
      }
    }

    // 6. Events / Actions (English & Tamil)
    if (lower.contains('service') || lower.contains('serviced') || lower.contains('à®šà®°à¯à®µà¯€à®¸à¯')) events.add('Service');
    if (lower.contains('repair') || lower.contains('fixed') || lower.contains('à®°à®¿à®ªà¯à®ªà¯‡à®°à¯') || lower.contains('à®šà®°à®¿à®šà¯†à®¯à¯à®¤à®¾à®°à¯')) events.add('Repair');
    if (lower.contains('purchase') || lower.contains('bought') || lower.contains('à®µà®¾à®™à¯à®•à®¿à®©à¯‡à®©à¯')) events.add('Purchase');
    if (lower.contains('doctor') || lower.contains('prescription') || lower.contains('à®®à®°à¯à®¤à¯à®¤à¯à®µà®°à¯') || lower.contains('à®®à®°à¯à®¨à¯à®¤à¯')) events.add('Medical');
    if (lower.contains('warranty') || lower.contains('à®µà®¾à®°à®£à¯à®Ÿà®¿')) events.add('Warranty');

    // Title formulation
    String title;
    if (things.isNotEmpty && events.isNotEmpty) {
      title = '${things.first} ${events.first}';
    } else if (people.isNotEmpty && events.isNotEmpty) {
      title = '${events.first} with ${people.first}';
    } else if (things.isNotEmpty) {
      title = '${things.first} Record';
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
      contactPhone: detectedPhone ?? base.contactPhone,
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
    final phone = top['contact_phone'] as String?;
    return AskResult(
      answer: '$title: $summary',
      confidence: 'high',
      relatedEntities: people,
      suggestedActions: [
        if (people.isNotEmpty || phone != null)
          ActionProposal(
            actionType: 'message',
            title: 'Contact ${people.isNotEmpty ? people[0] : 'Technician'} on WhatsApp',
            channel: 'whatsapp',
            recipientName: people.isNotEmpty ? people[0] : null,
            recipientContact: phone,
          ),
      ],
    );
  }

  static ContextBridgeResult _localContextBridge(String statement, List<Map<String, dynamic>> evidence) {
    final hasPast = evidence.isNotEmpty;
    final past = hasPast ? evidence.first : <String, dynamic>{};
    final person = (past['people'] as List? ?? []).isNotEmpty ? past['people'][0] as String : 'the service technician';
    final thing = (past['things'] as List? ?? []).isNotEmpty ? past['things'][0] as String : 'appliance';
    final phone = past['contact_phone'] as String?;

    return ContextBridgeResult(
      detectedProblem: statement,
      relevantMemorySummary: hasPast ? (past['summary'] as String? ?? 'Past memory located.') : 'No previous records found.',
      whyRelevant: hasPast ? 'Found past records related to $thing.' : 'You can log a new record or action.',
      targetPerson: hasPast ? person : null,
      targetPhone: phone,
      suggestedActions: [
        if (hasPast)
          ActionProposal(
            actionType: 'message',
            title: 'Message $person on WhatsApp',
            channel: 'whatsapp',
            recipientName: person,
            recipientContact: phone,
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