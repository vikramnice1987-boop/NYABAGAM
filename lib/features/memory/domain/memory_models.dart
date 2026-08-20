class MemoryModel {
  const MemoryModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.status,
    required this.createdAt,
    this.sourceId,
    this.occurredAt,
    this.people = const [],
    this.organizations = const [],
    this.things = const [],
    this.amount,
    this.currency,
    this.rawSourceSnippet,
  });

  final String id;
  final String title;
  final String summary;
  final String status;
  final DateTime createdAt;
  final String? sourceId;
  final DateTime? occurredAt;
  final List<String> people;
  final List<String> organizations;
  final List<String> things;
  final double? amount;
  final String? currency;
  final String? rawSourceSnippet;

  factory MemoryModel.fromRow(Map<String, dynamic> row) {
    final meta = Map<String, dynamic>.from(row['metadata'] as Map? ?? {});
    return MemoryModel(
      id: row['id'] as String,
      title: row['title'] as String? ?? 'Untitled memory',
      summary: row['summary'] as String? ?? '',
      status: row['status'] as String? ?? 'confirmed',
      createdAt: DateTime.parse(row['created_at'] as String),
      sourceId: row['source_id'] as String?,
      occurredAt: row['occurred_at'] != null ? DateTime.tryParse(row['occurred_at'] as String) : null,
      people: List<String>.from(meta['people'] as List? ?? []),
      organizations: List<String>.from(meta['organizations'] as List? ?? []),
      things: List<String>.from(meta['things'] as List? ?? []),
      amount: (meta['amount'] is num) ? (meta['amount'] as num).toDouble() : null,
      currency: meta['currency'] as String?,
      rawSourceSnippet: meta['raw_content'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'source_id': sourceId,
    'occurred_at': occurredAt?.toIso8601String(),
    'metadata': {
      'people': people,
      'organizations': organizations,
      'things': things,
      'amount': amount,
      'currency': currency,
      'raw_content': rawSourceSnippet,
    },
  };

  factory MemoryModel.fromJson(Map<String, dynamic> json) => MemoryModel.fromRow(json);
}

class ContextBridgeResult {
  const ContextBridgeResult({
    required this.detectedProblem,
    required this.relevantMemorySummary,
    required this.whyRelevant,
    required this.suggestedActions,
    this.targetPerson,
  });

  final String detectedProblem;
  final String relevantMemorySummary;
  final String whyRelevant;
  final List<ActionProposal> suggestedActions;
  final String? targetPerson;

  factory ContextBridgeResult.fromJson(Map<String, dynamic> json) {
    final rawActions = json['suggested_actions'] as List? ?? [];
    return ContextBridgeResult(
      detectedProblem: json['detected_problem'] as String? ?? '',
      relevantMemorySummary: json['relevant_memory_summary'] as String? ?? '',
      whyRelevant: json['why_relevant'] as String? ?? '',
      targetPerson: json['target_person'] as String?,
      suggestedActions: rawActions
          .map((a) => ActionProposal.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList(),
    );
  }
}

class ActionProposal {
  const ActionProposal({
    required this.actionType,
    required this.title,
    this.recipientName,
    this.recipientContact,
    this.draftMessage,
    this.channel = 'whatsapp',
  });

  final String actionType;
  final String title;
  final String? recipientName;
  final String? recipientContact;
  final String? draftMessage;
  final String channel;

  factory ActionProposal.fromJson(Map<String, dynamic> json) {
    return ActionProposal(
      actionType: json['action_type'] as String? ?? 'message',
      title: json['title'] as String? ?? 'Suggested Action',
      recipientName: json['recipient_name'] as String?,
      recipientContact: json['recipient_contact'] as String?,
      draftMessage: json['draft_message'] as String?,
      channel: json['channel'] as String? ?? 'whatsapp',
    );
  }

  Map<String, dynamic> toJson() => {
    'action_type': actionType,
    'title': title,
    'recipient_name': recipientName,
    'recipient_contact': recipientContact,
    'draft_message': draftMessage,
    'channel': channel,
  };
}

class AskResult {
  const AskResult({
    required this.answer,
    this.confidence = 'high',
    this.evidenceIds = const [],
    this.suggestedActions = const [],
    this.relatedEntities = const [],
  });

  final String answer;
  final String confidence;
  final List<String> evidenceIds;
  final List<ActionProposal> suggestedActions;
  final List<String> relatedEntities;

  factory AskResult.fromJson(Map<String, dynamic> json) {
    final rawActions = json['suggested_actions'] as List? ?? [];
    return AskResult(
      answer: json['answer'] as String? ?? '',
      confidence: json['confidence'] as String? ?? 'high',
      evidenceIds: List<String>.from(json['evidence_ids'] as List? ?? []),
      relatedEntities: List<String>.from(json['related_entities'] as List? ?? []),
      suggestedActions: rawActions
          .map((a) => ActionProposal.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList(),
    );
  }
}