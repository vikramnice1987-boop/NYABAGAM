import 'package:flutter/animation.dart';

/// Motion is what separates glass from a flat translucent rectangle: surfaces
/// should settle rather than snap. Everything here is spring-flavoured and
/// interruptible.
class NyMotion {
  const NyMotion._();

  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration normal = Duration(milliseconds: 340);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration ambient = Duration(seconds: 18);

  /// Primary easing: fast out, long gentle settle. Reads as weight.
  static const Curve settle = Cubic(0.32, 0.72, 0.0, 1.0);

  /// Slight overshoot for elements that appear/expand.
  static const Curve spring = Cubic(0.34, 1.28, 0.64, 1.0);

  /// Symmetric easing for colour/opacity crossfades.
  static const Curve fade = Curves.easeInOutCubic;

  /// Entrance offset for staggered list/section reveals.
  static const double entranceOffset = 16.0;

  /// Per-item delay when staggering a group.
  static Duration stagger(int index) =>
      Duration(milliseconds: (index * 55).clamp(0, 440));
}
