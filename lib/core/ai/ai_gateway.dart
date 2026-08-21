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
    DateTime? warrantyExpiresAt;
    DateTime? serviceDueAt;
    String? machineType;
    final relationships = <DetectedRelationship>[];
    final now = DateTime.now();

    // 1. Phone / WhatsApp Number Extraction
    final phoneRegex = RegExp(r'(?:\+?91[\-\s]?)?[6-9]\d{9}\b');
    final phoneMatch = phoneRegex.firstMatch(content);
    if (phoneMatch != null) {
      detectedPhone = phoneMatch.group(0)?.replaceAll(RegExp(r'[\-\s]'), '');
    }

    // 2. Cost / Amount Extraction
    final amtRegex = RegExp(r'(?:[\u20B9\$\u00A3]|rs\.?|inr|rupees)\s*([\d,]+(?:\.\d+)?)', caseSensitive: false);
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

    // 3. Multi-language Things / Machines / Appliances (Order by length descending)
    final knownThings = {
      'washing machine': 'Washing Machine',
      'air conditioner': 'AC',
      'water purifier': 'Water Purifier',
      'ro water purifier': 'Water Purifier',
      'microwave oven': 'Microwave Oven',
      'refrigerator': 'Refrigerator',
      'motorcycle': 'Bike',
      'television': 'Television',
      'water heater': 'Geyser',
      'computer': 'Computer',
      'inverter': 'Inverter',
      'scooter': 'Scooter',
      'battery': 'Battery',
      'microwave': 'Microwave Oven',
      'laptop': 'Laptop',
      'fridge': 'Refrigerator',
      'geyser': 'Geyser',
      'motor': 'Water Motor',
      'phone': 'Phone',
      'bike': 'Bike',
      'car': 'Car',
      'fan': 'Ceiling Fan',
      'ro': 'Water Purifier',
      'tv': 'Television',
      'ac': 'AC',
    };
    for (final entry in knownThings.entries) {
      final key = entry.key;
      final matched = key.length <= 3
          ? RegExp(r'\b' + key + r'\b').hasMatch(lower)
          : lower.contains(key);
      if (matched) {
        things.add(entry.value);
        machineType ??= entry.value;
      }
    }

    // 4. Warranty Period / Expiry Date Detection
    if (lower.contains('2 year warranty') || lower.contains('2 years warranty') || lower.contains('2 yr warranty')) {
      warrantyExpiresAt = now.add(const Duration(days: 730));
    } else if (lower.contains('1 year warranty') || lower.contains('1 yr warranty') || lower.contains('12 months warranty') || lower.contains('1 year guarantee')) {
      warrantyExpiresAt = now.add(const Duration(days: 365));
    } else if (lower.contains('6 month warranty') || lower.contains('6 months warranty') || lower.contains('6 mo warranty') || lower.contains('6 month guarantee')) {
      warrantyExpiresAt = now.add(const Duration(days: 180));
    } else if (lower.contains('3 month warranty') || lower.contains('3 months warranty') || lower.contains('3 mo warranty')) {
      warrantyExpiresAt = now.add(const Duration(days: 90));
    } else if (lower.contains('1 month warranty') || lower.contains('1 mo warranty')) {
      warrantyExpiresAt = now.add(const Duration(days: 30));
    } else if (lower.contains('2 days warranty') || lower.contains('expire in 2 days') || lower.contains('expires in 2 days')) {
      warrantyExpiresAt = now.add(const Duration(days: 2));
    }

    // 5. Next Service Due Date Detection
    if (lower.contains('next service in 6 months') || lower.contains('service due in 6 months')) {
      serviceDueAt = now.add(const Duration(days: 180));
    } else if (lower.contains('next service in 3 months') || lower.contains('service due in 3 months')) {
      serviceDueAt = now.add(const Duration(days: 90));
    } else if (lower.contains('next service in 1 year') || lower.contains('service due in 1 year')) {
      serviceDueAt = now.add(const Duration(days: 365));
    } else if (lower.contains('next service in 2 days') || lower.contains('service due in 2 days')) {
      serviceDueAt = now.add(const Duration(days: 2));
    }

    // 6. Multi-language Organizations & Brands
    final knownOrgs = {
      'coolcare': 'CoolCare', 'samsung': 'Samsung', 'lg': 'LG',
      'sony': 'Sony', 'apple': 'Apple', 'amazon': 'Amazon',
      'flipkart': 'Flipkart', 'honda': 'Honda', 'tata': 'Tata',
      'apollo': 'Apollo Clinic', 'urban company': 'Urban Company',
      'croma': 'Croma', 'voltas': 'Voltas', 'whirlpool': 'Whirlpool',
      'panasonic': 'Panasonic', 'daikin': 'Daikin', 'dell': 'Dell',
      'hp': 'HP', 'lenovo': 'Lenovo', 'asus': 'Asus',
    };
    for (final entry in knownOrgs.entries) {
      if (lower.contains(entry.key)) orgs.add(entry.value);
    }

    // 7. Extract Names
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
    // Also extract first capitalized word if not a common stop word (e.g. "Ravi serviced my AC")
    if (words.isNotEmpty) {
      final first = words[0].replaceAll(RegExp(r'[^\w]'), '');
      if (first.isNotEmpty && first[0] == first[0].toUpperCase() && first.length > 2 && !knownThings.containsKey(first.toLowerCase())) {
        final commonStopWords = {'my', 'the', 'yesterday', 'today', 'last', 'i', 'we', 'this', 'our', 'new', 'who', 'what', 'when'};
        if (!commonStopWords.contains(first.toLowerCase())) {
          people.add(first);
        }
      }
    }

    // 8. Events / Actions
    if (lower.contains('service') || lower.contains('serviced')) events.add('Service');
    if (lower.contains('repair') || lower.contains('fixed')) events.add('Repair');
    if (lower.contains('purchase') || lower.contains('bought')) events.add('Purchase');
    if (lower.contains('doctor') || lower.contains('prescription')) events.add('Medical');
    if (lower.contains('warranty') || lower.contains('guarantee') || lower.contains('expire')) events.add('Warranty');

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
      warrantyExpiresAt: warrantyExpiresAt ?? base.warrantyExpiresAt,
      serviceDueAt: serviceDueAt ?? base.serviceDueAt,
      machineType: machineType ?? base.machineType,
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