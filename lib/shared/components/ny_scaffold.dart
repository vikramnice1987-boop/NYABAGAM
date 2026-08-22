import 'package:flutter/material.dart';

import '../../core/theme/ny_motion.dart';
import '../../core/theme/ny_spacing.dart';
import '../../core/theme/ny_typography.dart';
import 'ny_aurora_background.dart';

/// Standard page shell.
///
/// Paints the aurora wallpaper, then lays the header and body directly on top
/// of it. The header is intentionally *not* glass: it sits on the wallpaper so
/// each screen spends its blur budget on content surfaces instead of chrome.
class NyScaffold extends StatelessWidget {
  const NyScaffold({
    required this.body,
    this.title,
    this.eyebrow,
    this.actions,
    this.leading,
    this.showBack = false,
    this.onBack,
    this.floatingActionButton,
    this.bottomBar,
    this.intensity = 1.0,
    this.padBottomForNav = false,
    super.key,
  });

  final Widget body;
  final String? title;

  /// Small all-caps label above the title.
  final String? eyebrow;

  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? floatingActionButton;
  final Widget? bottomBar;
  final double intensity;

  /// Adds clearance so scrollable content is not hidden behind the floating
  /// glass nav bar.
  final bool padBottomForNav;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHeader = title != null || showBack || leading != null || (actions?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
      body: NyAuroraBackground(
        intensity: intensity,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (hasHeader)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    NySpacing.space16,
                    NySpacing.space12,
                    NySpacing.space16,
                    NySpacing.space8,
                  ),
                  child: Row(
                    children: <Widget>[
                      if (showBack)
                        _HeaderIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                        )
                      else
                        ?leading,
                      if (showBack || leading != null)
                        const SizedBox(width: NySpacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (eyebrow != null) ...<Widget>[
                              Text(
                                eyebrow!.toUpperCase(),
                                style: NyTypography.overline.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: NySpacing.space4),
                            ],
                            if (title != null)
                              Text(
                                title!,
                                style: NyTypography.headlineLarge.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (actions != null) ...<Widget>[
                        const SizedBox(width: NySpacing.space8),
                        ...actions!,
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: padBottomForNav
                      ? Padding(
                          padding: const EdgeInsets.only(
                            bottom: NySpacing.navBarClearance,
                          ),
                          child: body,
                        )
                      : body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular translucent icon button used in page headers.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// Circular translucent icon button, exported for use in page `actions`.
class NyIconButton extends StatelessWidget {
  const NyIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.colorScheme.onSurface;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: fg.withValues(alpha: 0.06),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: fg),
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts a child into place. Used to stagger sections so a screen
/// assembles itself instead of appearing all at once.
class NyReveal extends StatelessWidget {
  const NyReveal({
    required this.child,
    this.index = 0,
    super.key,
  });

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: NyMotion.normal + NyMotion.stagger(index),
      curve: NyMotion.settle,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * NyMotion.entranceOffset),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
