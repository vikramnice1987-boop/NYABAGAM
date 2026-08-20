import 'package:uuid/uuid.dart';

enum MemoryStatus { candidate, confirmed, archived, forgotten }

class DetectedRelationship {
  const DetectedRelationship({
    required this.source,
    required this.relationship,
    required this.target,
  });

  final String source;
  final String relationship;
  final String target;

  factory DetectedRelationship.fromJson(Map<String, dynamic> json) => DetectedRelationship(
    source: json['source'] as String? ?? '',
    relationship: json['relationship'] as String? ?? 'related_to',
    target: json['target'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'source': source,
    'relationship': relationship,
    'target': target,
  };
}

class MemoryCandidate {
  const MemoryCandidate({
    required this.id,
    required this.sourceId,
    required this.rawContent,
    required this.title,
    required this.summary,
    required this.capturedAt,
    this.people = const [],
    this.organizations = const [],
    this.things = const [],
    this.places = const [],
    this.events = const [],
    this.relationships = const [],
    this.amount,
    this.currency,
    this.occurredAt,
    this.attachmentBase64,
    this.attachmentName,
    this.attachmentType,
    this.contactPhone,
    this.warrantyExpiresAt,
    this.serviceDueAt,
    this.machineType,
    this.status = MemoryStatus.candidate,
  });

  factory MemoryCandidate.fromText(String content, {
    String? attachmentBase64,
    String? attachmentName,
    String? attachmentType,
    String? contactPhone,
    DateTime? warrantyExpiresAt,
    DateTime? serviceDueAt,
    String? machineType,
  }) {
    final normalized = content.trim();
    final summary = normalized.length > 160
        ? '${normalized.substring(0, 157)}...'
        : normalized;
    final uuid = const Uuid().v4();
    return MemoryCandidate(
      id: uuid,
      sourceId: 'src_$uuid',
      rawContent: normalized,
      title: 'New memory',
      summary: summary,
      capturedAt: DateTime.now(),
      attachmentBase64: attachmentBase64,
      attachmentName: attachmentName,
      attachmentType: attachmentType,
      contactPhone: contactPhone,
      warrantyExpiresAt: warrantyExpiresAt,
      serviceDueAt: serviceDueAt,
      machineType: machineType,
    );
  }

  final String id;
  final String sourceId;
  final String rawContent;
  final String title;
  final String summary;
  final DateTime capturedAt;
  final List<String> people;
  final List<String> organizations;
  final List<String> things;
  final List<String> places;
  final List<String> events;
  final List<DetectedRelationship> relationships;
  final double? amount;
  final String? currency;
  final DateTime? occurredAt;
  final String? attachmentBase64;
  final String? attachmentName;
  final String? attachmentType;
  final String? contactPhone;
  final DateTime? warrantyExpiresAt;
  final DateTime? serviceDueAt;
  final String? machineType;
  final MemoryStatus status;

  MemoryCandidate copyWith({
    String? title,
    String? summary,
    List<String>? people,
    List<String>? organizations,
    List<String>? things,
    List<String>? places,
    List<String>? events,
    List<DetectedRelationship>? relationships,
    double? amount,
    String? currency,
    DateTime? occurredAt,
    String? attachmentBase64,
    String? attachmentName,
    String? attachmentType,
    String? contactPhone,
    DateTime? warrantyExpiresAt,
    DateTime? serviceDueAt,
    String? machineType,
    MemoryStatus? status,
  }) => MemoryCandidate(
    id: id,
    sourceId: sourceId,
    rawContent: rawContent,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    capturedAt: capturedAt,
    people: people ?? this.people,
    organizations: organizations ?? this.organizations,
    things: things ?? this.things,
    places: places ?? this.places,
    events: events ?? this.events,
    relationships: relationships ?? this.relationships,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    occurredAt: occurredAt ?? this.occurredAt,
    attachmentBase64: attachmentBase64 ?? this.attachmentBase64,
    attachmentName: attachmentName ?? this.attachmentName,
    attachmentType: attachmentType ?? this.attachmentType,
    contactPhone: contactPhone ?? this.contactPhone,
    warrantyExpiresAt: warrantyExpiresAt ?? this.warrantyExpiresAt,
    serviceDueAt: serviceDueAt ?? this.serviceDueAt,
    machineType: machineType ?? this.machineType,
    status: status ?? this.status,
  );

  MemoryCandidate confirm() => copyWith(status: MemoryStatus.confirmed);

  MemoryCandidate withUnderstanding(Map<String, dynamic> data) {
    final parsedRelationships = (data['relationships'] as List<dynamic>? ?? [])
        .map((r) => DetectedRelationship.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();

    double? parsedAmount;
    if (data['amount'] != null) {
      parsedAmount = (data['amount'] is num) ? (data['amount'] as num).toDouble() : double.tryParse(data['amount'].toString());
    }

    DateTime? parsedOccurredAt;
    if (data['occurred_at'] != null) {
      parsedOccurredAt = DateTime.tryParse(data['occurred_at'].toString());
    }

    DateTime? parsedWarrantyExpiresAt;
    if (data['warranty_expires_at'] != null) {
      parsedWarrantyExpiresAt = DateTime.tryParse(data['warranty_expires_at'].toString());
    }

    DateTime? parsedServiceDueAt;
    if (data['service_due_at'] != null) {
      parsedServiceDueAt = DateTime.tryParse(data['service_due_at'].toString());
    }

    return copyWith(
      title: data['title'] as String? ?? title,
      summary: data['summary'] as String? ?? summary,
      people: List<String>.from(data['people'] as List? ?? []),
      organizations: List<String>.from(data['organizations'] as List? ?? []),
      things: List<String>.from(data['things'] as List? ?? []),
      places: List<String>.from(data['places'] as List? ?? []),
      events: List<String>.from(data['events'] as List? ?? []),
      relationships: parsedRelationships,
      amount: parsedAmount,
      currency: data['currency'] as String? ?? currency,
      occurredAt: parsedOccurredAt,
      contactPhone: data['contact_phone'] as String? ?? contactPhone,
      warrantyExpiresAt: parsedWarrantyExpiresAt ?? warrantyExpiresAt,
      serviceDueAt: parsedServiceDueAt ?? serviceDueAt,
      machineType: data['machine_type'] as String? ?? machineType,
    );
  }
}