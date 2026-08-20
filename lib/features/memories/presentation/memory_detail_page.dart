import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_entity_chip.dart';
import '../../../shared/components/ny_evidence_card.dart';
import '../../memory/domain/memory_models.dart';

class MemoryDetailPage extends StatelessWidget {
  const MemoryDetailPage({required this.memory, super.key});

  final MemoryModel memory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NySpacing.space20),
        children: [
          Text(
            memory.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Recorded on ${memory.createdAt.toLocal()}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: NySpacing.space20),

          // Attached Image or Bill Review
          if (memory.attachmentBase64 != null) ...[
            Text('Attached Document / Photo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            NyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attachment, color: NyColors.accentLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          memory.attachmentName ?? 'Attached Document',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(memory.attachmentBase64!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NySpacing.space20),
          ],

          // Summary Card
          NyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Structured Memory Fact',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(memory.summary, style: theme.textTheme.bodyLarge),
                if (memory.amount != null) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount recorded:'),
                      Text(
                        '₹${memory.amount!.toStringAsFixed(0)} ${memory.currency ?? 'INR'}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space20),

          // Connected Entities
          Text('Connected Entities', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in memory.people) NyEntityChip(label: p, type: NyEntityType.person),
              for (final t in memory.things) NyEntityChip(label: t, type: NyEntityType.thing),
              for (final o in memory.organizations) NyEntityChip(label: o, type: NyEntityType.organization),
            ],
          ),
          const SizedBox(height: NySpacing.space24),

          // Provenance Evidence
          Text('Evidence Provenance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          NyEvidenceCard(
            title: memory.title,
            snippet: memory.rawSourceSnippet ?? memory.summary,
            date: memory.occurredAt ?? memory.createdAt,
          ),
          const SizedBox(height: NySpacing.space32),

          // Action Shortcuts
          if (memory.things.isNotEmpty)
            NyButton(
              label: 'Check Context for ${memory.things.first}',
              icon: Icons.lightbulb_outline,
              onPressed: () => context.push(
                '/context-bridge',
                extra: 'My ${memory.things.first} isn\'t working.',
              ),
            ),
        ],
      ),
    );
  }
}