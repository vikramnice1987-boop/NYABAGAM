import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../shared/components/ny_scaffold.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_loading_state.dart';
import '../../memory/data/memory_repository.dart';
import '../../memory/domain/memory_models.dart';

class ContextBridgePage extends StatefulWidget {
  const ContextBridgePage({required this.statement, super.key});

  final String statement;

  @override
  State<ContextBridgePage> createState() => _ContextBridgePageState();
}

class _ContextBridgePageState extends State<ContextBridgePage> {
  ContextBridgeResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    setState(() => _isLoading = true);
    final repo = MemoryRepositoryFactory.current;
    final res = await repo.findContext(widget.statement);
    if (mounted) {
      setState(() {
        _result = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NyScaffold(
      title: 'Context Bridge',
      showBack: true,
      body: _isLoading
          ? const NyLoadingState(message: 'Analyzing context and retrieving history...')
          : ListView(
              padding: const EdgeInsets.all(NySpacing.space20),
              children: [
                // Step 1: Current Situation
                Text(
                  'Current Situation',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                NyCard(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.statement,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NySpacing.space20),

                // Step 2: Past Memory & Why Relevant
                Text(
                  'Relevant Historical Memory',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                NyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result?.relevantMemorySummary ?? 'No past memory found.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const Divider(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, size: 16, color: theme.colorScheme.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _result?.whyRelevant ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(180),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NySpacing.space24),

                // Step 3: Suggested Actions
                Text(
                  'Suggested Next Action',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: NySpacing.space12),

                if (_result != null && _result!.suggestedActions.isNotEmpty)
                  for (final action in _result!.suggestedActions) ...[
                    NyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          if (action.draftMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '"${action.draftMessage}"',
                              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                          const SizedBox(height: 12),
                          NyButton(
                            label: 'Review and Approve',
                            icon: Icons.check_circle_outline,
                            onPressed: () => context.push('/action-approval', extra: action),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: NySpacing.space12),
                  ],
              ],
            ),
    );
  }
}