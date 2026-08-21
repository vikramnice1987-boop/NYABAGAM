import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final name = memory.people.isNotEmpty ? memory.people.first : 'there';
    final thing = memory.machineType ?? (memory.things.isNotEmpty ? memory.things.first : 'appliance');
    final msg = Uri.encodeComponent('Hi $name, regarding my $thing service/warranty, I wanted to check on it.');
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening WhatsApp for $phone')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasWarranty = memory.warrantyExpiresAt != null;
    final hasService = memory.serviceDueAt != null;
    final wDays = memory.warrantyDaysRemaining;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Detail', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NySpacing.space16),
        children: [
          Text(
            memory.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Recorded on ${memory.createdAt.toLocal()}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160)),
          ),
          const SizedBox(height: NySpacing.space16),

          // Machine Warranty & Lifecycle Status Alert Banner
          if (hasWarranty || hasService || memory.machineType != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (wDays != null && wDays <= 2)
                    ? NyColors.statusError.withAlpha(25)
                    : theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (wDays != null && wDays <= 2) ? NyColors.statusError.withAlpha(140) : NyColors.accentLight.withAlpha(80),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        size: 20,
                        color: (wDays != null && wDays <= 2) ? NyColors.statusError : NyColors.accentLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${memory.machineType ?? "Machine"} Lifecycle & Reminders',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: (wDays != null && wDays <= 2) ? NyColors.statusError : NyColors.accentLight,
                          ),
                        ),
                      ),
                      if (hasWarranty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (wDays != null && wDays <= 2)
                                ? (wDays < 0 ? NyColors.statusError : NyColors.statusWarning)
                                : NyColors.statusSuccess,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            wDays != null && wDays <= 2
                                ? (wDays < 0 ? 'EXPIRED' : 'EXPIRES IN ${wDays}d')
                                : (wDays != null ? '$wDays days valid' : 'Active'),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (hasWarranty) ...[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Warranty Expiration:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                              Text(
                                '${memory.warrantyExpiresAt!.year}-${memory.warrantyExpiresAt!.month.toString().padLeft(2, '0')}-${memory.warrantyExpiresAt!.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (hasService) ...[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Next Service Due:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                              Text(
                                '${memory.serviceDueAt!.year}-${memory.serviceDueAt!.month.toString().padLeft(2, '0')}-${memory.serviceDueAt!.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: NyColors.entityPerson),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: NySpacing.space16),
          ],

          // Attached Image or Bill Review
          if (memory.attachmentBase64 != null) ...[
            Text('Attached Document / Photo', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            NyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attachment_rounded, color: NyColors.accentLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          memory.attachmentName ?? 'Attached Document',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: NySpacing.space16),
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
                        'Rs. ${memory.amount!.toStringAsFixed(0)} ${memory.currency ?? 'INR'}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space16),

          // WhatsApp Quick Action if Phone Available
          if (memory.contactPhone != null && memory.contactPhone!.isNotEmpty) ...[
            NyCard(
              backgroundColor: NyColors.statusSuccess.withAlpha(20),
              child: Row(
                children: [
                  const Icon(Icons.chat_rounded, color: NyColors.statusSuccess, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WhatsApp Contact Connected', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(memory.contactPhone!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(180))),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NyColors.statusSuccess,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () => _openWhatsApp(context, memory.contactPhone!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NySpacing.space16),
          ],

          // Connected Entities
          Text('Connected Entities', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in memory.people) NyEntityChip(label: p, type: NyEntityType.person),
              for (final t in memory.things) NyEntityChip(label: t, type: NyEntityType.thing),
              for (final o in memory.organizations) NyEntityChip(label: o, type: NyEntityType.organization),
            ],
          ),
          const SizedBox(height: NySpacing.space20),

          // Provenance Evidence
          Text('Evidence Provenance', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          NyEvidenceCard(
            title: memory.title,
            snippet: memory.rawSourceSnippet ?? memory.summary,
            date: memory.occurredAt ?? memory.createdAt,
          ),
          const SizedBox(height: NySpacing.space24),

          if (memory.things.isNotEmpty)
            NyButton(
              label: 'Check Context Bridge for ${memory.things.first}',
              icon: Icons.lightbulb_outline_rounded,
              onPressed: () => context.push(
                '/context-bridge',
                extra: 'My ${memory.things.first} isn\'t working.',
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}