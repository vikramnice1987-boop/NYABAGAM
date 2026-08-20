import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../memory/data/memory_repository.dart';

class OutcomeRecordPage extends StatefulWidget {
  const OutcomeRecordPage({required this.thingName, super.key});

  final String thingName;

  @override
  State<OutcomeRecordPage> createState() => _OutcomeRecordPageState();
}

class _OutcomeRecordPageState extends State<OutcomeRecordPage> {
  final _notesController = TextEditingController(text: 'Ravi fixed the AC.');
  String _selectedStatus = 'resolved';
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveOutcome() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) return;

    setState(() => _isSaving = true);
    await MemoryRepositoryFactory.current.recordOutcome(
      thingName: widget.thingName,
      outcomeSummary: notes,
      newStatus: _selectedStatus == 'resolved' ? 'active' : 'needs_service',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Outcome recorded! ${widget.thingName} status updated to resolved.'),
        ),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Outcome'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NySpacing.space20),
        children: [
          Text(
            'Complete the Memory Loop',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Recording what happened updates ${widget.thingName} status and provides context for future needs.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(180),
            ),
          ),
          const SizedBox(height: NySpacing.space20),

          NyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Service Outcome Result:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'resolved', child: Text('Issue Resolved (Working)')),
                    DropdownMenuItem(value: 'partial', child: Text('Partially Resolved')),
                    DropdownMenuItem(value: 'unresolved', child: Text('Unresolved (Needs Further Action)')),
                  ],
                  onChanged: (v) => setState(() => _selectedStatus = v!),
                ),
                const SizedBox(height: 16),
                const Text('Outcome Details / Notes:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Ravi replaced the capacitor and serviced the filter.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space24),

          NyButton(
            label: 'Save Outcome & Update Memory',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: _saveOutcome,
          ),
        ],
      ),
    );
  }
}