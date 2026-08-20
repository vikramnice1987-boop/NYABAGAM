import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../memory/domain/memory_models.dart';

class ActionApprovalPage extends StatefulWidget {
  const ActionApprovalPage({required this.proposal, super.key});

  final ActionProposal proposal;

  @override
  State<ActionApprovalPage> createState() => _ActionApprovalPageState();
}

class _ActionApprovalPageState extends State<ActionApprovalPage> {
  late final TextEditingController _messageController;
  bool _isApproved = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: widget.proposal.draftMessage ??
          'Hi ${widget.proposal.recipientName ?? ''}, my appliance needs service. Are you available?',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _approveAndDispatch() async {
    setState(() => _isApproved = true);
    final text = _messageController.text;
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action approved and dispatched. Track the outcome once completed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Action Approval'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NySpacing.space20),
        children: [
          Text(
            'Review Action Before Execution',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('NYABAGAM never sends messages or contacts people without your explicit approval.'),
          const SizedBox(height: NySpacing.space20),

          // Proposal Info
          NyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      'Action Type: ${widget.proposal.actionType.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: NyColors.entityPerson.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Recipient: ${widget.proposal.recipientName ?? 'Contact'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: NyColors.entityPerson),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Message Draft (You can edit before sending):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Edit message draft...',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space24),

          if (!_isApproved) ...[
            NyButton(
              label: 'Approve & Send via WhatsApp',
              icon: Icons.send,
              onPressed: _approveAndDispatch,
            ),
            const SizedBox(height: 12),
            NyButton(
              label: 'Cancel Action',
              variant: NyButtonVariant.outline,
              onPressed: () => context.pop(),
            ),
          ] else ...[
            NyCard(
              backgroundColor: NyColors.statusSuccess.withAlpha(20),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: NyColors.statusSuccess),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Action approved and marked as Dispatched.',
                      style: TextStyle(fontWeight: FontWeight.w600, color: NyColors.statusSuccess),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NySpacing.space20),
            NyButton(
              label: 'Record Service Outcome (When Done)',
              icon: Icons.assignment_turned_in_outlined,
              onPressed: () => context.push('/record-outcome', extra: 'AC'),
            ),
          ],
        ],
      ),
    );
  }
}