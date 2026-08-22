import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/ny_colors.dart';
import '../core/theme/ny_elevation.dart';
import '../core/theme/ny_motion.dart';
import '../core/theme/ny_radius.dart';
import '../core/theme/ny_spacing.dart';
import '../core/theme/ny_typography.dart';
import '../shared/components/ny_glass.dart';

/// Height of the floating glass tab bar. Screens reserve clearance for it via
/// [NySpacing.navBarClearance].
const double kNavBarHeight = 66.0;

/// The app shell: branch content with a floating glass tab bar over it.
///
/// The bar detaches from the bottom edge so the wallpaper and content scroll
/// visibly beneath it — the single clearest signal that the chrome is glass
/// and not an opaque bar. Screens reserve room for it via
/// `NySpacing.navBarClearance`.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'Home'),
    _NavItem(Icons.history_rounded, Icons.history_rounded, 'Memories'),
    _NavItem(Icons.search_rounded, Icons.search_rounded, 'Ask'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        // The shell must be given tight constraints; a loose Stack would let
        // the branch Navigator collapse to zero height.
        fit: StackFit.expand,
        children: <Widget>[
          navigationShell,
          Positioned(
            left: NySpacing.space16,
            right: NySpacing.space16,
            bottom: (bottomInset > 0 ? bottomInset : NySpacing.space12) + NySpacing.space4,
            // Height is explicit: with only left/right/bottom set the bar gets
            // loose vertical constraints and can be squashed below its content,
            // clipping the labels.
            height: kNavBarHeight,
            child: _GlassTabBar(
              currentIndex: navigationShell.currentIndex,
              onSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              items: _items,
            ),
          ),
        ],
      ),
      floatingActionButton: navigationShell.currentIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: NySpacing.space56),
              child: _CaptureFab(onPressed: () => context.push('/capture')),
            )
          : null,
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({
    required this.currentIndex,
    required this.onSelected,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    return NyGlass(
      level: NyGlassLevel.floating,
      borderRadius: NyRadius.borderPill,
      padding: const EdgeInsets.symmetric(
        horizontal: NySpacing.space6,
        vertical: NySpacing.space6,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / items.length;
          return Stack(
            children: <Widget>[
              // The selected pill slides between slots rather than blinking.
              AnimatedPositioned(
                duration: NyMotion.normal,
                curve: NyMotion.settle,
                left: slot * currentIndex,
                top: 0,
                bottom: 0,
                width: slot,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: NySpacing.space4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        NyColors.accentGradient[0].withValues(alpha: 0.85),
                        NyColors.accentGradient[1].withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: NyRadius.borderPill,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: NyColors.accentGradient[1].withValues(alpha: 0.42),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  for (int i = 0; i < items.length; i++)
                    Expanded(
                      child: _TabButton(
                        item: items[i],
                        selected: i == currentIndex,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? Colors.white
        : theme.colorScheme.onSurface.withValues(alpha: 0.62);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: NyRadius.borderPill,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: NyMotion.fast,
              curve: NyMotion.spring,
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(height: NySpacing.space2),
            AnimatedDefaultTextStyle(
              duration: NyMotion.fast,
              style: NyTypography.labelSmall.copyWith(color: color),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary capture action. Carries the accent gradient and a pronounced glow
/// so it stays the most prominent target on the home surface.
class _CaptureFab extends StatelessWidget {
  const _CaptureFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Capture a memory',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: NySpacing.space20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: NyColors.accentGradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: NyRadius.borderPill,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: NyColors.accentGradient[2].withValues(alpha: 0.46),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
              const SizedBox(width: NySpacing.space8),
              Text(
                'Capture',
                style: NyTypography.labelLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
