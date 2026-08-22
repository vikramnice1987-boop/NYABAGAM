import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_elevation.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../core/theme/ny_typography.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_empty_state.dart';
import '../../../shared/components/ny_entity_chip.dart';
import '../../../shared/components/ny_scaffold.dart';
import '../../memory/domain/memory_models.dart';

class MemorySavedPage extends StatelessWidget {
  const MemorySavedPage({required this.memory, super.key});

  final MemoryModel memory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NyScaffold(
      body: Padding(
        padding: const EdgeInsets.all(NySpacing.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            NyReveal(
              child: Column(
                children: [
                  const Center(
                    child: NyMedallion(
                      icon: Icons.check_rounded,
                      color: NyColors.statusSuccess,
                      size: 96,
                    ),
                  ),
                  const SizedBox(height: NySpacing.space24),
                  Text(
                    'Memory saved',
                    style: NyTypography.displaySmall.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: NySpacing.space8),
                  Text(
                    'Linked into your knowledge graph with verified evidence provenance.',
                    style: NyTypography.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: NySpacing.space28),

            NyReveal(
              index: 1,
              child: NyCard(
                level: NyGlassLevel.floating,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.title,
                      style: NyTypography.titleLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: NySpacing.space8),
                    Text(
                      memory.summary,
                      style: NyTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    if (memory.people.isNotEmpty ||
                        memory.things.isNotEmpty ||
                        memory.organizations.isNotEmpty) ...[
                      const SizedBox(height: NySpacing.space14),
                      Wrap(
                        spacing: NySpacing.space6,
                        runSpacing: NySpacing.space6,
                        children: [
                          for (final p in memory.people)
                            NyEntityChip(label: p, type: NyEntityType.person),
                          for (final t in memory.things)
                            NyEntityChip(label: t, type: NyEntityType.thing),
                          for (final o in memory.organizations)
                            NyEntityChip(label: o, type: NyEntityType.organization),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),

            NyButton(
              label: 'Ask about this',
              icon: Icons.search_rounded,
              variant: NyButtonVariant.secondary,
              onPressed: () => context.go('/ask'),
            ),
            const SizedBox(height: NySpacing.space12),
            NyButton(
              label: 'Back to home',
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }
}
