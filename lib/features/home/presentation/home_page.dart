import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_radius.dart';
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: NyColors.accentLight.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology_rounded, color: NyColors.accentLight, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'NYABAGAM',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
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
          padding: const EdgeInsets.all(NySpacing.space16),
          children: [
            // Hero Welcome Banner
            Container(
              padding: const EdgeInsets.all(NySpacing.space20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: NyRadius.borderLg,
                border: Border.all(color: theme.colorScheme.outline.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: NyColors.accentLight.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('AI MEMORY LOOP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NyColors.accentLight, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your personal memory, with instant context.',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Capture service records, warranties, and contacts in Tamil or English. Connect past facts to present needs.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(180)),
                  ),
                  const SizedBox(height: 16),
                  NyButton(
                    label: 'Capture a thought or voice note',
                    icon: Icons.add_circle_outline_rounded,
                    onPressed: () async {
                      await context.push('/capture');
                      _loadData();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: NySpacing.space20),

            // 3 Quick Action Tiles
            Row(
              children: [
                Expanded(
                  child: _buildQuickTile(
                    theme: theme,
                    icon: Icons.mic_rounded,
                    title: 'Voice Note',
                    subtitle: 'தமிழ் / English',
                    color: NyColors.accentLight,
                    onTap: () async {
                      await context.push('/capture');
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickTile(
                    theme: theme,
                    icon: Icons.photo_camera_rounded,
                    title: 'Photo Scan',
                    subtitle: 'Bills & Labels',
                    color: NyColors.entityPerson,
                    onTap: () async {
                      await context.push('/capture');
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickTile(
                    theme: theme,
                    icon: Icons.search_rounded,
                    title: 'Ask Memory',
                    subtitle: 'Fast Recall',
                    color: NyColors.entityOrg,
                    onTap: () => context.go('/ask'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: NySpacing.space20),

            // Context Bridge Experience Card
            NyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, size: 20, color: NyColors.statusWarning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Context Bridge (AI Action Trigger)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Experience how NYABAGAM connects present situations to past memory and drafts WhatsApp action:',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: const Text('"My AC isn\'t working"'),
                        onPressed: () => context.push('/context-bridge', extra: 'My AC isn\'t working.'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: const Text('"Laptop screen check"'),
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
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/history'),
                  child: const Text('View all', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (_isLoading)
              const NyLoadingState(message: 'Loading memories...')
            else if (_recentMemories.isEmpty)
              NyCard(
                child: Padding(
                  padding: const EdgeInsets.all(NySpacing.space20),
                  child: Column(
                    children: [
                      Icon(Icons.psychology_outlined, size: 40, color: theme.colorScheme.outline),
                      const SizedBox(height: 10),
                      const Text(
                        'No memories saved yet.',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try capturing "Ravi serviced my AC today for ₹800" or a voice note in தமிழ்.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final mem in _recentMemories.take(4)) ...[
                NyCard(
                  onTap: () => context.push('/memory-detail', extra: mem),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              mem.title,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (mem.attachmentBase64 != null)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.attachment_rounded, size: 16, color: NyColors.accentLight),
                            ),
                          if (mem.contactPhone != null && mem.contactPhone!.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.chat_rounded, size: 14, color: NyColors.statusSuccess),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mem.summary,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
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

  Widget _buildQuickTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: NyRadius.borderMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: NyRadius.borderMd,
          border: Border.all(color: theme.colorScheme.outline.withAlpha(80)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11), maxLines: 1),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withAlpha(150)), maxLines: 1),
          ],
        ),
      ),
    );
  }
}