import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_radius.dart';
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
  late final TextEditingController _phoneController;
  bool _isApproved = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: widget.proposal.draftMessage ??
          'Hi ${widget.proposal.recipientName ?? ''}, regarding my appliance, I would like to schedule a service check. Are you available?',
    );
    _phoneController = TextEditingController(
      text: widget.proposal.recipientContact ?? '',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _approveAndDispatch() async {
    setState(() => _isApproved = true);
    final text = _messageController.text;
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'[^\d]'), '');

    Uri uri;
    if (phone.isNotEmpty) {
      uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}');
    } else {
      uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action approved and dispatched to WhatsApp.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Action Approval', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NySpacing.space16),
        children: [
          Text(
            'Review Action Before Execution',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'NYABAGAM never sends messages without your explicit approval.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160)),
          ),
          const SizedBox(height: NySpacing.space16),

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
                      'Action: ${widget.proposal.actionType.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: NyColors.statusSuccess.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_rounded, size: 14, color: NyColors.statusSuccess),
                          const SizedBox(width: 4),
                          Text(
                            'Recipient: ${widget.proposal.recipientName ?? 'Technician'}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NyColors.statusSuccess),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text('WhatsApp Phone Number:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                    hintText: 'e.g. +91 98400 12345 (Optional)',
                    border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),

                const Text('Message Draft (Editable):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space24),

          if (!_isApproved) ...[
            NyButton(
              label: 'Approve & Send via WhatsApp',
              icon: Icons.send_rounded,
              onPressed: _approveAndDispatch,
            ),
            const SizedBox(height: 10),
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
                  Icon(Icons.check_circle_rounded, color: NyColors.statusSuccess, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Action dispatched to WhatsApp. Log the outcome once the service completes.',
                      style: TextStyle(fontWeight: FontWeight.w700, color: NyColors.statusSuccess, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NySpacing.space20),
            NyButton(
              label: 'Record Service Outcome (When Done)',
              icon: Icons.assignment_turned_in_rounded,
              onPressed: () => context.push('/record-outcome', extra: 'AC'),
            ),
          ],
        ],
      ),
    );
  }
}