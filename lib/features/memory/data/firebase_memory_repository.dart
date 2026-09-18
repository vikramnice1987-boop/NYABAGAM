// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/ai/ai_gateway.dart';
import '../domain/memory_candidate.dart';
import '../domain/memory_models.dart';
import 'memory_repository.dart';

/// User-scoped Firestore repository for the NYABAGAM memory lifecycle.
///
/// Attachments are moved to Cloud Storage before the memory document is
/// committed. The Firestore document retains only its Storage path and
/// download URL; it never persists the capture's base64 payload.
class FirebaseMemoryRepository implements MemoryRepository {
  FirebaseMemoryRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required String userId,
  })  : _firestore = firestore,
        _storage = storage,
        _userId = userId;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String _userId;

  CollectionReference<Map<String, dynamic>> get _memories =>
      _firestore.collection('users').doc(_userId).collection('memories');

  CollectionReference<Map<String, dynamic>> get _sources =>
      _firestore.collection('users').doc(_userId).collection('sources');

  CollectionReference<Map<String, dynamic>> get _entities =>
      _firestore.collection('users').doc(_userId).collection('entities');

  @override
  Future<MemoryModel> confirm(MemoryCandidate candidate) async {
    final now = DateTime.now().toUtc();
    final sourceRef = _sources.doc(candidate.id);
    final memoryRef = _memories.doc(candidate.id);
    final attachment = await _uploadAttachment(candidate);

    final memory = MemoryModel(
      id: candidate.id,
      title: candidate.title,
      summary: candidate.summary,
      status: 'confirmed',
      createdAt: now,
      sourceId: sourceRef.id,
      occurredAt: candidate.occurredAt?.toUtc() ?? now,
      people: candidate.people,
      organizations: candidate.organizations,
      things: candidate.things,
      amount: candidate.amount,
      currency: candidate.currency,
      rawSourceSnippet: candidate.rawContent,
      attachmentName: candidate.attachmentName,
      attachmentType: candidate.attachmentType,
      attachmentUrl: attachment?.url,
      attachmentStoragePath: attachment?.path,
      contactPhone: candidate.contactPhone,
      warrantyExpiresAt: candidate.warrantyExpiresAt?.toUtc(),
      serviceDueAt: candidate.serviceDueAt?.toUtc(),
      machineType: candidate.machineType,
    );

    final batch = _firestore.batch();
    batch.set(sourceRef, <String, dynamic>{
      'id': sourceRef.id,
      'capture_type': _captureType(candidate),
      'raw_content': candidate.rawContent,
      'created_at': now.toIso8601String(),
      'attachment_storage_path': attachment?.path,
    });
    batch.set(memoryRef, memory.toJson());
    for (final person in candidate.people) {
      batch.set(_entities.doc(_entityId('person', person)), <String, dynamic>{
        'kind': 'person',
        'name': person,
        'updated_at': now.toIso8601String(),
      }, SetOptions(merge: true));
    }
    for (final organization in candidate.organizations) {
      batch.set(
        _entities.doc(_entityId('organization', organization)),
        <String, dynamic>{
          'kind': 'organization',
          'name': organization,
          'updated_at': now.toIso8601String(),
        },
        SetOptions(merge: true),
      );
    }
    for (final thing in candidate.things) {
      batch.set(_entities.doc(_entityId('thing', thing)), <String, dynamic>{
        'kind': 'thing',
        'name': thing,
        'current_status': 'active',
        'updated_at': now.toIso8601String(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
    return memory;
  }

  @override
  Future<List<MemoryModel>> confirmed() async {
    final snapshot = await _memories
        .where('status', whereIn: const <String>['confirmed', 'active'])
        .orderBy('created_at', descending: true)
        .get();
    return snapshot.docs
        .map((document) => MemoryModel.fromJson(document.data()))
        .toList(growable: false);
  }

  @override
  Future<List<MemoryModel>> search(String query) async {
    final memories = await confirmed();
    final tokens = _searchTokens(query);
    if (tokens.isEmpty) return memories;

    return memories.where((memory) {
      final searchable = <String>[
        memory.title,
        memory.summary,
        ...memory.people,
        ...memory.things,
        ...memory.organizations,
      ].join(' ').toLowerCase();
      return tokens.any(searchable.contains);
    }).toList(growable: false);
  }

  @override
  Future<ContextBridgeResult> findContext(String statement) async {
    final matching = await search(statement);
    return AiGateway.generateContextBridge(statement, _evidenceFrom(matching));
  }

  @override
  Future<void> recordOutcome({
    required String thingName,
    required String outcomeSummary,
    required String newStatus,
  }) async {
    final now = DateTime.now().toUtc();
    final memoryRef = _memories.doc();
    final memory = MemoryModel(
      id: memoryRef.id,
      title: '$thingName Status Update',
      summary: outcomeSummary,
      status: 'confirmed',
      createdAt: now,
      things: <String>[thingName],
    );

    final batch = _firestore.batch();
    batch.set(memoryRef, memory.toJson());
    batch.set(_entities.doc(_entityId('thing', thingName)), <String, dynamic>{
      'kind': 'thing',
      'name': thingName,
      'current_status': newStatus,
      'updated_at': now.toIso8601String(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Future<List<MemoryModel>> getExpiringSoon({
    int daysThreshold = 2,
  }) async {
    final memories = await confirmed();
    return memories.where((memory) {
      final warrantyDays = memory.warrantyDaysRemaining;
      final serviceDays = memory.serviceDaysRemaining;
      return (warrantyDays != null &&
              warrantyDays >= 0 &&
              warrantyDays <= daysThreshold) ||
          (serviceDays != null &&
              serviceDays >= 0 &&
              serviceDays <= daysThreshold);
    }).toList(growable: false);
  }

  @override
  Future<List<MemoryModel>> getWarrantiesAndReminders() async {
    final memories = await confirmed();
    final reminders = memories
        .where(
          (memory) =>
              memory.warrantyExpiresAt != null ||
              memory.serviceDueAt != null ||
              memory.things.isNotEmpty,
        )
        .toList();
    reminders.sort((a, b) {
      final aDate = a.warrantyExpiresAt ?? a.serviceDueAt ?? a.createdAt;
      final bDate = b.warrantyExpiresAt ?? b.serviceDueAt ?? b.createdAt;
      return aDate.compareTo(bDate);
    });
    return reminders;
  }

  @override
  Future<void> deleteMemory(String id) async {
    final memory = await _memories.doc(id).get();
    final data = memory.data();
    final metadata =
        Map<String, dynamic>.from(data?['metadata'] as Map? ?? <String, dynamic>{});
    final storagePath = metadata['attachment_storage_path'] as String?;
    await _memories.doc(id).delete();
    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        await _storage.ref(storagePath).delete();
      } catch (_) {
        // A missing attachment must not make a user-visible deletion fail.
      }
    }
  }

  Future<_StoredAttachment?> _uploadAttachment(MemoryCandidate candidate) async {
    final encoded = candidate.attachmentBase64;
    if (encoded == null || encoded.isEmpty) return null;

    final name = _safeFileName(candidate.attachmentName ?? 'capture');
    final path = <String>[
      'users',
      _userId,
      'captures',
      candidate.id,
      name,
    ].join('/');
    final ref = _storage.ref(path);
    await ref.putData(
      base64Decode(encoded),
      SettableMetadata(contentType: _contentType(candidate.attachmentType)),
    );
    return _StoredAttachment(path: path, url: await ref.getDownloadURL());
  }

  String _captureType(MemoryCandidate candidate) =>
      candidate.attachmentType == null ? 'text' : 'attachment';

  String _entityId(String kind, String name) {
    final normalized = name.trim().toLowerCase().replaceAll(
          RegExp('[^a-z0-9]+'),
          '-',
        );
    final identifier = normalized.isEmpty ? 'unnamed' : normalized;
    return '$kind-$identifier';
  }

  String _safeFileName(String value) =>
      value.replaceAll(RegExp('[^a-zA-Z0-9._-]'), '_');

  String _contentType(String? value) {
    if (value == null || value.isEmpty) return 'application/octet-stream';
    if (value.contains('/')) return value;
    if (value == 'image') return 'image/jpeg';
    return 'application/octet-stream';
  }

  List<String> _searchTokens(String query) {
    const ignored = <String>{
      'who',
      'what',
      'when',
      'where',
      'how',
      'why',
      'did',
      'the',
      'for',
      'my',
      'is',
      'was',
      'in',
      'at',
      'on',
      'to',
    };
    return query
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9 ]'), ' ')
        .split(RegExp(' +'))
        .where((token) => token.isNotEmpty && !ignored.contains(token))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _evidenceFrom(List<MemoryModel> memories) =>
      memories
          .map(
            (memory) => <String, dynamic>{
              'title': memory.title,
              'summary': memory.summary,
              'people': memory.people,
              'things': memory.things,
              'organizations': memory.organizations,
              'contact_phone': memory.contactPhone,
            },
          )
          .toList(growable: false);
}

class _StoredAttachment {
  const _StoredAttachment({required this.path, required this.url});

  final String path;
  final String url;
}
