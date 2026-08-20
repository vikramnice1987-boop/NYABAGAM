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
  static MemoryCandidate _localUnderstand(String content, MemoryCandidate base) {
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

    // 2. Amount Extraction (₹, $, Rs, INR, ரூபாய்)
    final amtRegex = RegExp(r'(?:[₹$€£]|rs\.?|inr|ரூபாய்|ரூ\.?)\s*([\d,]+(?:\.\d+)?)', caseSensitive: false);
    final amtMatch = amtRegex.firstMatch(content);
    if (amtMatch != null) {
      final rawNum = amtMatch.group(1)?.replaceAll(',', '');
      if (rawNum != null) amount = double.tryParse(rawNum);
    } else {
      final plainNumRegex = RegExp(r'\b(?:for|paid|cost|price|fee|worth|செலவு|கொடுத்தேன்)\s*(?:of)?\s*([\d,]+(?:\.\d+)?)\b', caseSensitive: false);
      final plainMatch = plainNumRegex.firstMatch(content);
      if (plainMatch != null) {
        final rawNum = plainMatch.group(1)?.replaceAll(',', '');
        if (rawNum != null) amount = double.tryParse(rawNum);
      }
    }

    // 3. Multi-language Things / Appliances / Items (English & Tamil)
    final knownThings = {
      'ac': 'AC', 'air conditioner': 'Air Conditioner', 'ஏசி': 'AC',
      'car': 'Car', 'கார்': 'Car',
      'bike': 'Bike', 'பைக்': 'Bike', 'வண்டி': 'Two Wheeler',
      'laptop': 'Laptop', 'லேப்டாப்': 'Laptop',
      'phone': 'Phone', 'போன்': 'Phone', 'மொபைல்': 'Mobile Phone',
      'fridge': 'Refrigerator', 'refrigerator': 'Refrigerator', 'பிரிட்ஜ்': 'Refrigerator',
      'tv': 'Television', 'television': 'Television', 'டிவி': 'Television',
      'washing machine': 'Washing Machine', 'வாஷிங் மெஷின்': 'Washing Machine',
      'geyser': 'Geyser', 'கீசர்': 'Geyser',
      'inverter': 'Inverter', 'இன்வெர்ட்டர்': 'Inverter',
      'motor': 'Water Motor', 'மோட்டார்': 'Water Motor',
      'water purifier': 'Water Purifier', 'ro': 'RO Purifier',
      'fan': 'Ceiling Fan', 'ஃபேன்': 'Fan',
    };
    for (final entry in knownThings.entries) {
      if (lower.contains(entry.key)) things.add(entry.value);
    }

    // 4. Multi-language Organizations & Stores
    final knownOrgs = {
      'coolcare': 'CoolCare', 'samsung': 'Samsung', 'சாம்சங்': 'Samsung',
      'lg': 'LG', 'எல்ஜி': 'LG', 'sony': 'Sony', 'சோனி': 'Sony',
      'apple': 'Apple', 'amazon': 'Amazon', 'flipkart': 'Flipkart',
      'honda': 'Honda', 'ஹோண்டா': 'Honda', 'tata': 'Tata', 'டாடா': 'Tata',
      'apollo': 'Apollo Clinic', 'அப்போலோ': 'Apollo',
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
    if (lower.contains('service') || lower.contains('serviced') || lower.contains('சர்வீஸ்')) events.add('Service');
    if (lower.contains('repair') || lower.contains('fixed') || lower.contains('ரிப்பேர்') || lower.contains('சரிசெய்தார்')) events.add('Repair');
    if (lower.contains('purchase') || lower.contains('bought') || lower.contains('வாங்கினேன்')) events.add('Purchase');
    if (lower.contains('doctor') || lower.contains('prescription') || lower.contains('மருத்துவர்') || lower.contains('மருந்து')) events.add('Medical');
    if (lower.contains('warranty') || lower.contains('வாரண்டி')) events.add('Warranty');

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