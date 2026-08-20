import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ai/ai_gateway.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_evidence_card.dart';
import '../../../shared/components/ny_loading_state.dart';
import '../../memory/data/memory_repository.dart';
import '../../memory/domain/memory_models.dart';

class AskPage extends StatefulWidget {
  const AskPage({super.key});

  @override
  State<AskPage> createState() => _AskPageState();
}

class _AskPageState extends State<AskPage> {
  final _queryController = TextEditingController();
  AskResult? _result;
  List<MemoryModel> _matchingEvidence = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _ask(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    _queryController.text = q;
    setState(() {
      _isSearching = true;
      _result = null;
    });

    try {
      final repo = MemoryRepositoryFactory.current;
      final memories = await repo.search(q);
      _matchingEvidence = memories;

      final evidencePayload = memories.map((m) => {
        'title': m.title,
        'summary': m.summary,
        'people': m.people,
        'things': m.things,
        'organizations': m.organizations,
        'amount': m.amount,
        'date': m.occurredAt?.toIso8601String(),
      }).toList();

      final res = await AiGateway.ask(q, evidencePayload);
      if (mounted) {
        setState(() {
          _result = res;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask NYABAGAM'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NySpacing.space20),
        children: [
          Text(
            'Find any past detail naturally.',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask questions in plain language. Answers are strictly grounded in your confirmed memories.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(180),
            ),
          ),
          const SizedBox(height: NySpacing.space16),

          // Search Field
          TextField(
            controller: _queryController,
            textInputAction: TextInputAction.search,
            onSubmitted: _ask,
            decoration: InputDecoration(
              hintText: 'e.g., Who serviced my AC?',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => _ask(_queryController.text),
              ),
            ),
          ),
          const SizedBox(height: NySpacing.space12),

          // Example queries
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Who serviced my AC?'),
                onPressed: () => _ask('Who serviced my AC?'),
              ),
              ActionChip(
                label: const Text('How much did AC service cost?'),
                onPressed: () => _ask('How much did AC service cost?'),
              ),
              ActionChip(
                label: const Text('When was CoolCare last contacted?'),
                onPressed: () => _ask('When was CoolCare last contacted?'),
              ),
            ],
          ),
          const SizedBox(height: NySpacing.space24),

          if (_isSearching)
            const NyLoadingState(message: 'Searching memories and reasoning...')
          else if (_result != null) ...[
            // Answer Card
            NyCard(
              backgroundColor: theme.colorScheme.primaryContainer.withAlpha(100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Grounded Answer',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NySpacing.space12),
                  Text(
                    _result!.answer,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (_result!.suggestedActions.isNotEmpty) ...[
                    const SizedBox(height: NySpacing.space16),
                    NyButton(
                      label: _result!.suggestedActions.first.title,
                      icon: Icons.chat_outlined,
                      onPressed: () => context.push(
                        '/action-approval',
                        extra: _result!.suggestedActions.first,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: NySpacing.space20),

            // Evidence Section
            if (_matchingEvidence.isNotEmpty) ...[
              Text(
                'Source Evidence',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final ev in _matchingEvidence)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NyEvidenceCard(
                    title: ev.title,
                    snippet: ev.summary,
                    date: ev.occurredAt ?? ev.createdAt,
                    onTap: () => context.push('/memory-detail', extra: ev),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
