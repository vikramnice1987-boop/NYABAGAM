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
const double kNavBarHeight = 68.0;

/// The app shell: branch content with a floating glass capture dock over it.
///
/// Capture lives in the centre of the bar rather than in a separate floating
/// action button. The old FAB overlapped the bar and could swallow taps meant
/// for content underneath; folding it into the dock removes that collision and
/// makes the app's primary action permanently reachable from every tab.
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
            child: _CaptureDock(
              currentIndex: navigationShell.currentIndex,
              items: _items,
              onSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              onCapture: () => context.push('/capture'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _CaptureDock extends StatelessWidget {
  const _CaptureDock({
    required this.currentIndex,
    required this.items,
    required this.onSelected,
    required this.onCapture,
  });

  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onSelected;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return NyGlass(
      level: NyGlassLevel.floating,
      borderRadius: NyRadius.borderPill,
      padding: const EdgeInsets.symmetric(
        horizontal: NySpacing.space8,
        vertical: NySpacing.space6,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _TabButton(
              item: items[0],
              selected: currentIndex == 0,
              onTap: () => onSelected(0),
            ),
          ),
          Expanded(
            child: _TabButton(
              item: items[1],
              selected: currentIndex == 1,
              onTap: () => onSelected(1),
            ),
          ),
          _CaptureButton(onTap: onCapture),
          Expanded(
            child: _TabButton(
              item: items[2],
              selected: currentIndex == 2,
              onTap: () => onSelected(2),
            ),
          ),
          Expanded(
            child: _TabButton(
              item: items[3],
              selected: currentIndex == 3,
              onTap: () => onSelected(3),
            ),
          ),
        ],
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
    final accent = theme.colorScheme.primary;
    final color = selected
        ? accent
        : theme.colorScheme.onSurface.withValues(alpha: 0.58);

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
              scale: selected ? 1.1 : 1.0,
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
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The app's primary action, seated in the middle of the dock.
class _CaptureButton extends StatefulWidget {
  const _CaptureButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<_CaptureButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NySpacing.space6),
      child: Semantics(
        button: true,
        label: 'Capture a memory',
        child: GestureDetector(
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.93 : 1.0,
            duration: NyMotion.fast,
            curve: NyMotion.settle,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: NyColors.accentGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: NyColors.accentGradient[1].withValues(alpha: 0.50),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
