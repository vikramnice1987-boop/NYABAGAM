import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_entity_chip.dart';
import '../../../shared/components/ny_loading_state.dart';
import '../../memory/data/memory_repository.dart';
import '../../memory/domain/memory_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MemoryModel> _recentMemories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final memories = await MemoryRepositoryFactory.current.confirmed();
    if (mounted) {
      setState(() {
        _recentMemories = memories;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeController.instance.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NYABAGAM',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () {
              ThemeController.instance.toggleTheme();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(NySpacing.space20),
          children: [
            Text(
              'Your memory, with context.',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: NySpacing.space8),
            Text(
              'Capture meaningful facts, recognize when they become relevant, and take deliberate action.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
            const SizedBox(height: NySpacing.space24),

            // Primary Quick Capture Action
            NyButton(
              label: 'Capture a thought or voice note',
              icon: Icons.add,
              onPressed: () async {
                await context.push('/capture');
                _loadData();
              },
            ),
            const SizedBox(height: NySpacing.space24),

            // Context Bridge Experience Card
            NyCard(
              backgroundColor: theme.colorScheme.primaryContainer.withAlpha(120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 20, color: theme.colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Context Bridge Demo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NySpacing.space8),
                  Text(
                    'Experience how NYABAGAM connects present situations to past memory:',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: NySpacing.space12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.arrow_forward, size: 14),
                        label: const Text('"My AC isn\'t working"'),
                        onPressed: () => context.push('/context-bridge', extra: 'My AC isn\'t working.'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.arrow_forward, size: 14),
                        label: const Text('"Laptop service check"'),
                        onPressed: () => context.push('/context-bridge', extra: 'My laptop screen is flickering.'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: NySpacing.space24),

            // Recent Memories Section
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Memories',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/history'),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: NySpacing.space8),

            if (_isLoading)
              const NyLoadingState(message: 'Loading memories...')
            else if (_recentMemories.isEmpty)
              NyCard(
                child: Padding(
                  padding: const EdgeInsets.all(NySpacing.space16),
                  child: Column(
                    children: [
                      Icon(Icons.psychology_outlined, size: 36, color: theme.colorScheme.outline),
                      const SizedBox(height: 8),
                      const Text(
                        'No memories saved yet.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try capturing "Ravi serviced my AC today for ₹800" to test the memory loop.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final mem in _recentMemories.take(3)) ...[
                NyCard(
                  onTap: () => context.push('/memory-detail', extra: mem),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mem.title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mem.summary,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final p in mem.people) NyEntityChip(label: p, type: NyEntityType.person),
                          for (final t in mem.things) NyEntityChip(label: t, type: NyEntityType.thing),
                          for (final o in mem.organizations) NyEntityChip(label: o, type: NyEntityType.organization),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NySpacing.space12),
              ],
          ],
        ),
      ),
    );
  }
}