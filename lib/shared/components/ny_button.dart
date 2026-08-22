import 'package:flutter/material.dart';

import '../../core/theme/ny_colors.dart';
import '../../core/theme/ny_motion.dart';
import '../../core/theme/ny_radius.dart';
import '../../core/theme/ny_spacing.dart';
import '../../core/theme/ny_typography.dart';

enum NyButtonVariant { primary, secondary, outline, destructive }

/// Buttons in the glass system.
///
/// `primary` is the only element on a screen allowed to carry the saturated
/// accent gradient and its glow, so it always reads as the single next action.
/// The other variants are progressively quieter glass.
class NyButton extends StatefulWidget {
  const NyButton({
    required this.label,
    required this.onPressed,
    this.variant = NyButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final NyButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  State<NyButton> createState() => _NyButtonState();
}

class _NyButtonState extends State<NyButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final enabled = widget.onPressed != null && !widget.isLoading;

    final Color foreground;
    final Gradient? gradient;
    final Color? fill;
    final Border? border;
    final List<BoxShadow> glow;

    switch (widget.variant) {
      case NyButtonVariant.primary:
        foreground = Colors.white;
        gradient = const LinearGradient(
          colors: NyColors.accentGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
        fill = null;
        border = null;
        glow = <BoxShadow>[
          BoxShadow(
            color: NyColors.accentGradient[1].withValues(alpha: isDark ? 0.42 : 0.30),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ];

      case NyButtonVariant.secondary:
        foreground = theme.colorScheme.onSurface;
        gradient = null;
        fill = isDark ? NyColors.glassFillRaisedDark : NyColors.glassFillRaisedLight;
        border = Border.all(
          color: isDark ? NyColors.glassEdgeTopDark : NyColors.borderLight,
        );
        glow = const <BoxShadow>[];

      case NyButtonVariant.outline:
        foreground = theme.colorScheme.onSurface;
        gradient = null;
        fill = Colors.transparent;
        border = Border.all(
          color: isDark ? NyColors.glassEdgeTopDark : NyColors.borderLight,
        );
        glow = const <BoxShadow>[];

      case NyButtonVariant.destructive:
        foreground = Colors.white;
        gradient = null;
        fill = theme.colorScheme.error;
        border = null;
        glow = <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.error.withValues(alpha: 0.34),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ];
    }

    final Widget content = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : Row(
            mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (widget.icon != null) ...<Widget>[
                Icon(widget.icon, size: 19, color: foreground),
                const SizedBox(width: NySpacing.space8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: NyTypography.labelLarge.copyWith(color: foreground),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.45,
      duration: NyMotion.fast,
      child: AnimatedScale(
        scale: _pressed && enabled ? 0.972 : 1.0,
        duration: NyMotion.fast,
        curve: NyMotion.settle,
        child: GestureDetector(
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: Semantics(
            button: true,
            enabled: enabled,
            label: widget.label,
            child: Container(
              width: widget.isFullWidth ? double.infinity : null,
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: NySpacing.space20),
              decoration: BoxDecoration(
                gradient: gradient,
                color: fill,
                border: border,
                borderRadius: NyRadius.borderLg,
                boxShadow: enabled ? glow : const <BoxShadow>[],
              ),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}
