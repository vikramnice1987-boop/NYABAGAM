import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  late List<String> _people;
  late List<String> _things;
  late List<String> _orgs;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.candidate.title);
    _summaryController = TextEditingController(text: widget.candidate.summary);
    _people = List.from(widget.candidate.people);
    _things = List.from(widget.candidate.things);
    _orgs = List.from(widget.candidate.organizations);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _isSaving = true);
    final updatedCandidate = widget.candidate.copyWith(
      title: _titleController.text.trim(),
      summary: _summaryController.text.trim(),
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
        title: const Text('Review Memory Candidate'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NySpacing.space20),
        children: [
          Text(
            'Confirm Structured Details',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text('Review and edit the AI-extracted entities before saving permanently.'),
          const SizedBox(height: NySpacing.space20),

          // Title & Summary Inputs
          NyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Memory Title:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: 'Memory title'),
                ),
                const SizedBox(height: 16),
                const Text('Factual Summary:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _summaryController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Factual summary'),
                ),
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space20),

          // Detected Entities Section
          Text('Detected Entities & Links', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          NyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_people.isNotEmpty) ...[
                  const Text('People:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: _people.map((p) => NyEntityChip(
                      label: p,
                      type: NyEntityType.person,
                      onDeleted: () => setState(() => _people.remove(p)),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_things.isNotEmpty) ...[
                  const Text('Things / Appliances:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: _things.map((t) => NyEntityChip(
                      label: t,
                      type: NyEntityType.thing,
                      onDeleted: () => setState(() => _things.remove(t)),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_orgs.isNotEmpty) ...[
                  const Text('Organizations:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: _orgs.map((o) => NyEntityChip(
                      label: o,
                      type: NyEntityType.organization,
                      onDeleted: () => setState(() => _orgs.remove(o)),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
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

          // Actions
          NyButton(
            label: 'Confirm and Save Memory',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: _confirm,
          ),
          const SizedBox(height: 12),
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