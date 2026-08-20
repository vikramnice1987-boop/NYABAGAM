import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_radius.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_entity_chip.dart';
import '../../memory/data/memory_repository.dart';
import '../../memory/domain/memory_candidate.dart';

class MemoryReviewPage extends StatefulWidget {
  const MemoryReviewPage({required this.candidate, super.key});

  final MemoryCandidate candidate;

  @override
  State<MemoryReviewPage> createState() => _MemoryReviewPageState();
}

class _MemoryReviewPageState extends State<MemoryReviewPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _phoneController;
  late List<String> _people;
  late List<String> _things;
  late List<String> _orgs;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.candidate.title);
    _summaryController = TextEditingController(text: widget.candidate.summary);
    _phoneController = TextEditingController(text: widget.candidate.contactPhone ?? '');
    _people = List.from(widget.candidate.people);
    _things = List.from(widget.candidate.things);
    _orgs = List.from(widget.candidate.organizations);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _isSaving = true);
    final updatedCandidate = widget.candidate.copyWith(
      title: _titleController.text.trim(),
      summary: _summaryController.text.trim(),
      contactPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      people: _people,
      things: _things,
      organizations: _orgs,
    );

    try {
      final saved = await MemoryRepositoryFactory.current.confirm(updatedCandidate);
      if (mounted) {
        context.go('/remember', extra: saved);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save memory. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Memory Candidate', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NySpacing.space16),
        children: [
          Text(
            'Confirm Structured Details',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Review AI-extracted entities, attached photos, and WhatsApp contact details before storing.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160)),
          ),
          const SizedBox(height: NySpacing.space16),

          // Attached Image Review Card
          if (widget.candidate.attachmentBase64 != null) ...[
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
                          widget.candidate.attachmentName ?? 'Attached Image / Bill',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: NyColors.statusSuccess.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Verified', style: TextStyle(fontSize: 11, color: NyColors.statusSuccess, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(widget.candidate.attachmentBase64!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NySpacing.space16),
          ],

          // Title & Summary Inputs
          NyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Memory Title:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Factual Summary:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _summaryController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space16),

          // Contact Phone / WhatsApp Field
          NyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: NyColors.statusSuccess),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'WhatsApp / Contact Number (Optional):',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                    hintText: 'e.g. +91 98400 12345',
                    border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space16),

          // Detected Entities Section
          Text('Detected Entities & Identity Links', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          NyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_people.isNotEmpty) ...[
                  const Text('People:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: _people.map((p) => NyEntityChip(
                      label: p,
                      type: NyEntityType.person,
                      onDeleted: () => setState(() => _people.remove(p)),
                    )).toList(),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_things.isNotEmpty) ...[
                  const Text('Things / Appliances:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: _things.map((t) => NyEntityChip(
                      label: t,
                      type: NyEntityType.thing,
                      onDeleted: () => setState(() => _things.remove(t)),
                    )).toList(),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_orgs.isNotEmpty) ...[
                  const Text('Organizations:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: _orgs.map((o) => NyEntityChip(
                      label: o,
                      type: NyEntityType.organization,
                      onDeleted: () => setState(() => _orgs.remove(o)),
                    )).toList(),
                  ),
                  const SizedBox(height: 10),
                ],
                if (widget.candidate.amount != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recorded Cost:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '₹${widget.candidate.amount!.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.secondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space24),

          NyButton(
            label: 'Confirm and Save Memory',
            icon: Icons.check_circle_rounded,
            isLoading: _isSaving,
            onPressed: _confirm,
          ),
          const SizedBox(height: 10),
          NyButton(
            label: 'Edit Original Capture',
            variant: NyButtonVariant.outline,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}