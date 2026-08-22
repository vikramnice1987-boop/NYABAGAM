import 'package:flutter/material.dart';

import '../../core/theme/ny_colors.dart';

/// The vivid wash that every glass surface refracts.
///
/// Painted once per screen, behind everything, inside a [RepaintBoundary].
/// It is a plain [CustomPaint] of overlapping radial gradients — no blur, no
/// per-frame work — so the expensive `BackdropFilter` layers above it have
/// something rich to sample without costing anything themselves.
class NyAuroraBackground extends StatelessWidget {
  const NyAuroraBackground({
    this.child,
    this.intensity = 1.0,
    super.key,
  });

  final Widget? child;

  /// Scales orb opacity. Dial down on dense, text-heavy screens so the
  /// wallpaper never fights the content for contrast.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        RepaintBoundary(
          child: CustomPaint(
            painter: _AuroraPainter(isDark: isDark, intensity: intensity),
            isComplex: true,
            willChange: false,
          ),
        ),
        ?child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({required this.isDark, required this.intensity});

  final bool isDark;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    canvas.drawRect(
      bounds,
      Paint()
        ..color = isDark
            ? NyColors.wallpaperBaseDark
            : NyColors.wallpaperBaseLight,
    );

    // Orb placement is anchored to fractions of the viewport so the
    // composition survives every screen size.
    _orb(canvas, size, NyColors.orbIndigo, const Alignment(-0.75, -0.85), 1.05, isDark ? 0.55 : 0.34);
    _orb(canvas, size, NyColors.orbViolet, const Alignment(0.95, -0.55), 0.85, isDark ? 0.45 : 0.28);
    _orb(canvas, size, NyColors.orbCyan, const Alignment(-0.55, 0.45), 0.95, isDark ? 0.30 : 0.22);
    _orb(canvas, size, NyColors.orbMagenta, const Alignment(0.80, 0.95), 0.80, isDark ? 0.26 : 0.18);

    // Vignette: pulls focus to the centre and stops the orbs from washing out
    // text near the edges.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: <Color>[
            const Color(0x00000000),
            (isDark ? Colors.black : Colors.white).withValues(alpha: isDark ? 0.45 : 0.30),
          ],
          stops: const <double>[0.55, 1.0],
        ).createShader(bounds),
    );
  }

  void _orb(
    Canvas canvas,
    Size size,
    Color color,
    Alignment alignment,
    double radiusFactor,
    double alpha,
  ) {
    final centre = alignment.alongSize(size);
    final radius = size.shortestSide * radiusFactor;
    final rect = Rect.fromCircle(center: centre, radius: radius);

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withValues(alpha: alpha * intensity),
            color.withValues(alpha: 0),
          ],
          stops: const <double>[0.0, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.isDark != isDark || old.intensity != intensity;
}
