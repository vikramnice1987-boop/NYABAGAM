import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/ny_elevation.dart';
import '../../core/theme/ny_motion.dart';
import '../../core/theme/ny_radius.dart';
import '../../core/theme/ny_spacing.dart';

/// The single glass primitive for the whole app.
///
/// Everything that looks like frosted glass goes through this widget, which
/// keeps the blur/edge/specular/shadow cues consistent and — more importantly
/// — keeps the number of `BackdropFilter` layers auditable. Never nest one
/// [NyGlass] with [blur] enabled inside another: siblings are cheap, stacks
/// are not.
class NyGlass extends StatefulWidget {
  const NyGlass({
    required this.child,
    this.level = NyGlassLevel.raised,
    this.borderRadius = NyRadius.borderXl,
    this.padding = const EdgeInsets.all(NySpacing.space20),
    this.onTap,
    this.blur = true,
    this.tint,
    this.margin,
    super.key,
  });

  final Widget child;
  final NyGlassLevel level;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Set false for surfaces inside an already-blurred ancestor, or in dense
  /// lists where a blur per row would be wasteful.
  final bool blur;

  /// Optional accent wash laid over the neutral fill.
  final Gradient? tint;

  final EdgeInsetsGeometry? margin;

  /// Global kill switch for `BackdropFilter`. Disabled automatically on
  /// platforms where a full-screen blur stack is too expensive; see
  /// `bootstrap.dart`.
  static bool blurEnabled = true;

  @override
  State<NyGlass> createState() => _NyGlassState();
}

class _NyGlassState extends State<NyGlass> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final useBlur = widget.blur && NyGlass.blurEnabled;

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        gradient: NyElevation.fill(widget.level, brightness),
        borderRadius: widget.borderRadius,
      ),
      child: widget.tint == null
          ? _content(context)
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: widget.tint,
                borderRadius: widget.borderRadius,
              ),
              child: _content(context),
            ),
    );

    // Edge + specular are painted over the fill, but must stay *inside* the
    // BackdropFilter subtree.
    surface = CustomPaint(
      foregroundPainter: _GlassEdgePainter(
        borderRadius: widget.borderRadius,
        edge: NyElevation.edge(brightness),
        specular: NyElevation.specular(brightness),
      ),
      child: surface,
    );

    if (useBlur) {
      // `BackdropFilter` must be the direct child of the clip that bounds it.
      // Putting any painting widget between the two, or isolating the filter
      // inside a RepaintBoundary, leaves it sampling an empty backdrop — on
      // Flutter web that composites as an opaque fill and swallows the
      // content entirely.
      surface = BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: NyElevation.blurFor(widget.level),
          sigmaY: NyElevation.blurFor(widget.level),
        ),
        child: surface,
      );
    }

    Widget result = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: NyElevation.shadow(widget.level, brightness),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: surface,
      ),
    );

    if (widget.onTap != null) {
      // Glass compresses very slightly under a finger rather than rippling.
      result = AnimatedScale(
        scale: _pressed ? 0.978 : 1.0,
        duration: NyMotion.fast,
        curve: NyMotion.settle,
        child: result,
      );
    }

    if (widget.margin != null) {
      result = Padding(padding: widget.margin!, child: result);
    }

    return result;
  }

  Widget _content(BuildContext context) {
    final padded = Padding(padding: widget.padding, child: widget.child);
    if (widget.onTap == null) return padded;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: Semantics(button: true, child: padded),
    );
  }
}

/// Paints the refracted edge and the specular highlight along the top.
class _GlassEdgePainter extends CustomPainter {
  const _GlassEdgePainter({
    required this.borderRadius,
    required this.edge,
    required this.specular,
  });

  final BorderRadius borderRadius;
  final Gradient edge;
  final Color specular;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final rrect = borderRadius.toRRect(bounds).deflate(0.5);

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = edge.createShader(bounds)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Specular: a short bright line just inside the top edge, fading at both
    // ends. This is the cue that sells "lit from above".
    final inset = (borderRadius.topLeft.x * 0.6) + 4;
    if (size.width <= inset * 2) return;

    final lineRect = Rect.fromLTWH(inset, 0, size.width - inset * 2, 2);
    canvas.drawLine(
      Offset(inset, 1.25),
      Offset(size.width - inset, 1.25),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            specular.withValues(alpha: 0),
            specular,
            specular.withValues(alpha: 0),
          ],
          stops: const <double>[0.0, 0.5, 1.0],
        ).createShader(lineRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_GlassEdgePainter old) =>
      old.borderRadius != borderRadius ||
      old.edge != edge ||
      old.specular != specular;
}
