import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_elevation.dart';
import '../../../core/theme/ny_radius.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../core/theme/ny_typography.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_entity_chip.dart';
import '../../../shared/components/ny_loading_state.dart';
import '../../../shared/components/ny_scaffold.dart';
import '../../../shared/components/ny_section.dart';
import '../../../shared/components/ny_status_chip.dart';
import '../../memory/data/memory_repository.dart';
import '../../memory/domain/memory_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MemoryModel> _recentMemories = [];
  List<MemoryModel> _urgentReminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = MemoryRepositoryFactory.current;
    final memories = await repo.confirmed();
    final urgent = await repo.getExpiringSoon(daysThreshold: 2);
    if (mounted) {
      setState(() {
        _recentMemories = memories;
        _urgentReminders = urgent;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeController.instance.isDarkMode;

    return NyScaffold(
      padBottomForNav: true,
      leading: const _BrandMark(),
      title: 'NYABAGAM',
      actions: <Widget>[
        Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            NyIconButton(
              icon: Icons.shield_outlined,
              tooltip: 'Warranties and reminders',
              onPressed: () async {
                await context.push('/reminders');
                _loadData();
              },
            ),
            if (_urgentReminders.isNotEmpty)
              Positioned(
                right: 4,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: NyColors.statusError,
                    borderRadius: NyRadius.borderPill,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: NyColors.statusError.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    '${_urgentReminders.length}',
                    style: NyTypography.labelSmall.copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        NyIconButton(
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          onPressed: ThemeController.instance.toggleTheme,
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            NySpacing.gutter,
            NySpacing.space8,
            NySpacing.gutter,
            NySpacing.space24,
          ),
          children: <Widget>[
            if (_urgentReminders.isNotEmpty) ...<Widget>[
              NyReveal(child: _UrgentAlert(
                memory: _urgentReminders.first,
                count: _urgentReminders.length,
                onTap: () async {
                  await context.push('/reminders');
                  _loadData();
                },
              )),
              const SizedBox(height: NySpacing.space16),
            ],

            NyReveal(index: 1, child: _HeroCard(
              onCapture: () async {
                await context.push('/capture');
                _loadData();
              },
            )),
            const SizedBox(height: NySpacing.space16),

            NyReveal(index: 2, child: _QuickActions(
              onCapture: () async {
                await context.push('/capture');
                _loadData();
              },
              onReminders: () async {
                await context.push('/reminders');
                _loadData();
              },
              onAsk: () => context.go('/ask'),
            )),
            const SizedBox(height: NySpacing.space16),

            NyReveal(index: 3, child: _ContextBridgeCard()),
            const SizedBox(height: NySpacing.space28),

            NyReveal(
              index: 4,
              child: NySectionHeader(
                title: 'Recent memories',
                icon: Icons.bookmark_rounded,
                trailing: TextButton(
                  onPressed: () => context.go('/history'),
                  child: const Text('View all'),
                ),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: NySpacing.space40),
                child: NyLoadingState(message: 'Loading memories...'),
              )
            else if (_recentMemories.isEmpty)
              NyReveal(
                index: 5,
                child: NyCard(
                  child: Column(
                    children: <Widget>[
                      const NyMedallionSmall(icon: Icons.psychology_rounded),
                      const SizedBox(height: NySpacing.space14),
                      Text(
                        'No memories saved yet',
                        style: NyTypography.titleMedium.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: NySpacing.space6),
                      Text(
                        'Try capturing "Ravi serviced my AC today for Rs. 800, 6 month warranty" or record a voice note.',
                        style: NyTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              for (int i = 0; i < _recentMemories.take(4).length; i++) ...<Widget>[
                NyReveal(
                  index: 5 + i,
                  child: _MemoryCard(
                    memory: _recentMemories[i],
                    onTap: () => context.push('/memory-detail', extra: _recentMemories[i]),
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

/// Glowing app mark used in the home header.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: NyColors.accentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: NyRadius.borderSm,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: NyColors.accentGradient[1].withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 21),
    );
  }
}

/// Small circular icon badge for use inside cards.
class NyMedallionSmall extends StatelessWidget {
  const NyMedallionSmall({required this.icon, this.color, super.key});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.secondary;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tint.withValues(alpha: 0.16),
        border: Border.all(color: tint.withValues(alpha: 0.34)),
      ),
      child: Icon(icon, color: tint, size: 22),
    );
  }
}

/// High-priority warranty expiry banner.
class _UrgentAlert extends StatelessWidget {
  const _UrgentAlert({
    required this.memory,
    required this.count,
    required this.onTap,
  });

  final MemoryModel memory;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const alert = NyColors.statusError;
    return NyCard(
      onTap: onTap,
      level: NyGlassLevel.floating,
      padding: const EdgeInsets.all(NySpacing.space16),
      tint: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          alert.withValues(alpha: 0.24),
          alert.withValues(alpha: 0.06),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: alert,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: alert.withValues(alpha: 0.55),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: NySpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  count > 1 ? '$count warranties expiring' : 'Warranty expiring in 2 days',
                  style: NyTypography.titleSmall.copyWith(color: alert),
                ),
                const SizedBox(height: NySpacing.space2),
                Text(
                  '${memory.machineType ?? memory.title} needs attention. Tap to review or message the technician.',
                  style: NyTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.82),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: NySpacing.space8),
          const Icon(Icons.chevron_right_rounded, size: 20, color: alert),
        ],
      ),
    );
  }
}

/// The one hero surface on the home screen.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onCapture});

  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NyCard(
      level: NyGlassLevel.floating,
      padding: const EdgeInsets.all(NySpacing.space24),
      tint: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          NyColors.orbIndigo.withValues(alpha: 0.20),
          NyColors.orbMagenta.withValues(alpha: 0.05),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.9),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: NySpacing.space8),
              Flexible(
                child: Text(
                  'AI MEMORY - 2-DAY ALERTS',
                  style: NyTypography.overline.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: NySpacing.space16),
          Text(
            'Your personal memory,',
            style: NyTypography.displaySmall.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const NyGradientText('with instant context.'),
          const SizedBox(height: NySpacing.space10),
          Text(
            'Capture service records, warranties and contacts. Get proactive alerts two days before anything expires.',
            style: NyTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: NySpacing.space20),
          NyButton(
            label: 'Capture a thought',
            icon: Icons.auto_awesome_rounded,
            onPressed: onCapture,
          ),
        ],
      ),
    );
  }
}

/// Four-up shortcut row. Sized to survive a 360dp viewport.
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCapture,
    required this.onReminders,
    required this.onAsk,
  });

  final VoidCallback onCapture;
  final VoidCallback onReminders;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _QuickTile(
        icon: Icons.mic_rounded,
        title: 'Voice',
        subtitle: 'Multi-lang',
        color: NyColors.memoryCyanDark,
        onTap: onCapture,
      ),
      _QuickTile(
        icon: Icons.photo_camera_rounded,
        title: 'Scan',
        subtitle: 'Invoices',
        color: NyColors.entityPerson,
        onTap: onCapture,
      ),
      _QuickTile(
        icon: Icons.shield_rounded,
        title: 'Warranty',
        subtitle: '2-day alert',
        color: NyColors.entityThing,
        onTap: onReminders,
      ),
      _QuickTile(
        icon: Icons.search_rounded,
        title: 'Ask',
        subtitle: 'Fast recall',
        color: NyColors.entityOrg,
        onTap: onAsk,
      ),
    ];

    return Row(
      children: <Widget>[
        for (int i = 0; i < tiles.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: NySpacing.space8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NyCard(
      onTap: onTap,
      blur: false,
      borderRadius: NyRadius.borderMd,
      padding: const EdgeInsets.symmetric(
        horizontal: NySpacing.space4,
        vertical: NySpacing.space12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              border: Border.all(color: color.withValues(alpha: 0.32)),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: NySpacing.space8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: NyTypography.labelSmall.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: NySpacing.space2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtitle,
              maxLines: 1,
              style: NyTypography.labelSmall.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextBridgeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.lightbulb_rounded, size: 18, color: NyColors.statusWarning),
              const SizedBox(width: NySpacing.space8),
              Expanded(
                child: Text(
                  'Context Bridge',
                  style: NyTypography.titleMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NySpacing.space6),
          Text(
            'See how NYABAGAM links a situation happening now to what you already recorded, then drafts the message for you.',
            style: NyTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: NySpacing.space16),
          _BridgeTrigger(
            label: 'My AC is not working',
            onTap: () => context.push('/context-bridge', extra: 'My AC is not working.'),
          ),
          const SizedBox(height: NySpacing.space8),
          _BridgeTrigger(
            label: 'My laptop screen is flickering',
            onTap: () => context.push('/context-bridge', extra: 'My laptop screen is flickering.'),
          ),
        ],
      ),
    );
  }
}

class _BridgeTrigger extends StatelessWidget {
  const _BridgeTrigger({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: NySpacing.space14,
            vertical: NySpacing.space12,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? NyColors.glassFillSunkenDark
                : NyColors.glassFillSunkenLight,
            borderRadius: NyRadius.borderMd,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.arrow_forward_rounded,
                size: 15,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: NySpacing.space10),
              Expanded(
                child: Text(
                  label,
                  style: NyTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.memory, required this.onTap});

  final MemoryModel memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expiringSoon = memory.warrantyDaysRemaining != null &&
        memory.warrantyDaysRemaining! <= 2;

    return NyCard(
      onTap: onTap,
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  memory.title,
                  style: NyTypography.titleMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (memory.attachmentBase64 != null)
                Padding(
                  padding: const EdgeInsets.only(left: NySpacing.space6),
                  child: Icon(
                    Icons.attachment_rounded,
                    size: 15,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              if (memory.contactPhone != null && memory.contactPhone!.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: NySpacing.space6),
                  child: Icon(
                    Icons.chat_rounded,
                    size: 14,
                    color: NyColors.statusSuccess,
                  ),
                ),
            ],
          ),
          if (memory.warrantyExpiresAt != null) ...<Widget>[
            const SizedBox(height: NySpacing.space8),
            NyStatusChip(
              status: expiringSoon
                  ? 'expiring_soon'
                  : 'active',
            ),
          ],
          const SizedBox(height: NySpacing.space8),
          Text(
            memory.summary,
            style: NyTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (memory.people.isNotEmpty ||
              memory.things.isNotEmpty ||
              memory.organizations.isNotEmpty) ...<Widget>[
            const SizedBox(height: NySpacing.space12),
            Wrap(
              spacing: NySpacing.space6,
              runSpacing: NySpacing.space6,
              children: <Widget>[
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
    );
  }
}
