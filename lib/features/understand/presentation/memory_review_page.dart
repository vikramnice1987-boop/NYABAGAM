import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_radius.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../shared/components/ny_scaffold.dart';
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
  DateTime? _warrantyExpiresAt;
  DateTime? _serviceDueAt;
  String? _machineType;
  bool _isSaving = false;

  final List<String> _machineCategories = [
    'AC', 'Washing Machine', 'Refrigerator', 'Car', 'Bike', 'Laptop', 'Water Purifier', 'TV', 'Geyser', 'Inverter', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.candidate.title);
    _summaryController = TextEditingController(text: widget.candidate.summary);
    _phoneController = TextEditingController(text: widget.candidate.contactPhone ?? '');
    _people = List.from(widget.candidate.people);
    _things = List.from(widget.candidate.things);
    _orgs = List.from(widget.candidate.organizations);
    _warrantyExpiresAt = widget.candidate.warrantyExpiresAt;
    _serviceDueAt = widget.candidate.serviceDueAt;
    _machineType = widget.candidate.machineType ?? (_things.isNotEmpty ? _things.first : null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isWarranty}) async {
    final initialDate = (isWarranty ? _warrantyExpiresAt : _serviceDueAt) ?? DateTime.now().add(const Duration(days: 90));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        if (isWarranty) {
          _warrantyExpiresAt = picked;
        } else {
          _serviceDueAt = picked;
        }
      });
    }
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
      warrantyExpiresAt: _warrantyExpiresAt,
      serviceDueAt: _serviceDueAt,
      machineType: _machineType,
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
    final now = DateTime.now();

    return NyScaffold(
      title: 'Review candidate',
      eyebrow: 'Understand',
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.all(NySpacing.space16),
        children: [
          Text(
            'Confirm Structured Details',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Review AI-extracted entities, warranties, 2-day reminder dates, and WhatsApp contact.',
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
                        'Rs. ${widget.candidate.amount!.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.secondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space16),

          // Machine Warranty & Lifecycle Reminder Card
          Text('Machine Warranty & Service Reminders', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          NyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 20, color: NyColors.accentLight),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Warranty & Service Lifecycle (2-Day Alert)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'NYABAGAM automatically alerts you 2 days before warranty expires or service is due.',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(160)),
                ),
                const SizedBox(height: 14),

                // Machine Type Selector
                const Text('Machine / Appliance Category:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _machineCategories.map((type) {
                      final isSel = _machineType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => setState(() => _machineType = type),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSel ? NyColors.accentLight : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSel ? NyColors.accentLight : theme.colorScheme.outline.withAlpha(80),
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                                color: isSel ? Colors.white : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Warranty Expiry Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Warranty Expiry Date:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    if (_warrantyExpiresAt != null)
                      TextButton(
                        onPressed: () => setState(() => _warrantyExpiresAt = null),
                        child: const Text('Clear', style: TextStyle(fontSize: 11, color: NyColors.statusError)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _pickDate(isWarranty: true),
                  borderRadius: NyRadius.borderMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: NyRadius.borderMd,
                      border: Border.all(
                        color: _warrantyExpiresAt != null ? NyColors.accentLight : theme.colorScheme.outline.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 18, color: NyColors.accentLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _warrantyExpiresAt != null
                                ? '${_warrantyExpiresAt!.year}-${_warrantyExpiresAt!.month.toString().padLeft(2, '0')}-${_warrantyExpiresAt!.day.toString().padLeft(2, '0')} (${_warrantyExpiresAt!.difference(now).inDays} days remaining)'
                                : 'No warranty date set (Tap to pick date)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _warrantyExpiresAt != null ? FontWeight.w700 : FontWeight.normal,
                              color: _warrantyExpiresAt != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withAlpha(140),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('+6 Months', style: TextStyle(fontSize: 10)),
                      onPressed: () => setState(() => _warrantyExpiresAt = now.add(const Duration(days: 180))),
                    ),
                    ActionChip(
                      label: const Text('+1 Year', style: TextStyle(fontSize: 10)),
                      onPressed: () => setState(() => _warrantyExpiresAt = now.add(const Duration(days: 365))),
                    ),
                    ActionChip(
                      label: const Text('+2 Years', style: TextStyle(fontSize: 10)),
                      onPressed: () => setState(() => _warrantyExpiresAt = now.add(const Duration(days: 730))),
                    ),
                    ActionChip(
                      label: const Text('2 Days (Test Alert)', style: TextStyle(fontSize: 10, color: NyColors.statusWarning)),
                      onPressed: () => setState(() => _warrantyExpiresAt = now.add(const Duration(days: 2))),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Next Service Due Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Next Service Due Date:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    if (_serviceDueAt != null)
                      TextButton(
                        onPressed: () => setState(() => _serviceDueAt = null),
                        child: const Text('Clear', style: TextStyle(fontSize: 11, color: NyColors.statusError)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _pickDate(isWarranty: false),
                  borderRadius: NyRadius.borderMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: NyRadius.borderMd,
                      border: Border.all(
                        color: _serviceDueAt != null ? NyColors.entityPerson : theme.colorScheme.outline.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.build_circle_outlined, size: 18, color: NyColors.entityPerson),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _serviceDueAt != null
                                ? '${_serviceDueAt!.year}-${_serviceDueAt!.month.toString().padLeft(2, '0')}-${_serviceDueAt!.day.toString().padLeft(2, '0')} (${_serviceDueAt!.difference(now).inDays} days remaining)'
                                : 'No service due date set (Tap to pick date)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _serviceDueAt != null ? FontWeight.w700 : FontWeight.normal,
                              color: _serviceDueAt != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withAlpha(140),
                            ),
                          ),
                        ),
                      ],
                    ),
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}