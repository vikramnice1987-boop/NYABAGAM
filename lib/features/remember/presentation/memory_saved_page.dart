import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_entity_chip.dart';
import '../../memory/domain/memory_models.dart';

class MemorySavedPage extends StatelessWidget {
  const MemorySavedPage({required this.memory, super.key});

  final MemoryModel memory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Remembered'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(NySpacing.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Center(
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: NyColors.statusSuccess,
              ),
            ),
            const SizedBox(height: NySpacing.space16),
            Text(
              'Memory Confirmed & Saved',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Linked to your knowledge graph with verified evidence provenance.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(180)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NySpacing.space24),

            NyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(memory.summary, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final p in memory.people) NyEntityChip(label: p, type: NyEntityType.person),
                      for (final t in memory.things) NyEntityChip(label: t, type: NyEntityType.thing),
                      for (final o in memory.organizations) NyEntityChip(label: o, type: NyEntityType.organization),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),

            NyButton(
              label: 'Ask a Question about this',
              icon: Icons.search,
              variant: NyButtonVariant.secondary,
              onPressed: () => context.go('/ask'),
            ),
            const SizedBox(height: 12),
            NyButton(
              label: 'Back to Home',
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }
}