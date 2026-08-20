import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(stage.title)),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stage.description,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text('Feature foundation ready for implementation.'),
        ],
      ),
    ),
  );
}
