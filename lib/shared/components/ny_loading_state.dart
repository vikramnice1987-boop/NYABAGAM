import 'package:flutter/material.dart';

import '../../core/theme/ny_colors.dart';
import '../../core/theme/ny_motion.dart';
import '../../core/theme/ny_spacing.dart';
import '../../core/theme/ny_typography.dart';

/// Loading is expressed as a slow breathing orb rather than a spinner — it
/// reads as the system thinking, which suits an AI surface better than a
/// progress ring.
class NyLoadingState extends StatelessWidget {
  const NyLoadingState({this.message = 'Loading...', super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const NyPulseOrb(),
          const SizedBox(height: NySpacing.space20),
          Text(
            message,
            style: NyTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Breathing accent orb. Also used inline wherever the AI is working.
class NyPulseOrb extends StatefulWidget {
  const NyPulseOrb({this.size = 56, super.key});

  final double size;

  @override
  State<NyPulseOrb> createState() => _NyPulseOrbState();
}

class _NyPulseOrbState extends State<NyPulseOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_controller.value);
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: Container(
                width: widget.size * (0.62 + t * 0.30),
                height: widget.size * (0.62 + t * 0.30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: NyColors.accentGradient,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: NyColors.accentGradient[1]
                          .withValues(alpha: 0.30 + t * 0.34),
                      blurRadius: 22 + t * 18,
                      spreadRadius: t * 3,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Placeholder block for content that is still loading. Sized by the caller.
class NySkeleton extends StatefulWidget {
  const NySkeleton({
    this.width,
    this.height = 16,
    this.radius = 8,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<NySkeleton> createState() => _NySkeletonState();
}

class _NySkeletonState extends State<NySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: NyMotion.ambient ~/ 12,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: base.withValues(alpha: 0.05 + _controller.value * 0.06),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}
