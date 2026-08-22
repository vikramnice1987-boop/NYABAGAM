import 'package:flutter/material.dart';

import '../../../core/theme/ny_spacing.dart';
import '../../../core/theme/ny_typography.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_scaffold.dart';

enum MemoryFlowStage {
  capture('Capture', 'Bring in a thought, voice note, photo, or document.'),
  understand('Understand', 'Turn input into a reviewable memory candidate.'),
  remember('Remember', 'Save confirmed memories, people, things, and events.'),
  ask('Ask', 'Find the right memory using natural language.'),
  context('Context', 'Surface the details that matter in the current moment.'),
  action('Action', 'Prepare an intentional action for your approval.'),
  outcome('Outcome', 'Record what happened and update the memory.');

  const MemoryFlowStage(this.title, this.description);
  final String title;
  final String description;
  String get routeSegment => name;
}

class FlowStagePage extends StatelessWidget {
  const FlowStagePage({required this.stage, super.key});
  final MemoryFlowStage stage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NyScaffold(
      title: stage.title,
      eyebrow: 'Memory lifecycle',
      showBack: true,
      body: Padding(
        padding: const EdgeInsets.all(NySpacing.gutter),
        child: NyReveal(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stage.description,
                style: NyTypography.headlineMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: NySpacing.space20),
              NyCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.construction_rounded,
                      size: 18,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: NySpacing.space10),
                    Expanded(
                      child: Text(
                        'Feature foundation ready for implementation.',
                        style: NyTypography.bodyMedium.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
