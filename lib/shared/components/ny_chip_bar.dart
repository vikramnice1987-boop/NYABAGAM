import 'package:flutter/material.dart';

import '../../core/theme/ny_colors.dart';
import '../../core/theme/ny_motion.dart';
import '../../core/theme/ny_radius.dart';
import '../../core/theme/ny_spacing.dart';
import '../../core/theme/ny_typography.dart';

/// Horizontally scrolling filter rail.
///
/// The previous flat design let chips run off the right edge with no signal
/// that more existed. This fades the trailing edge whenever content overflows,
/// so a cut-off chip reads as scrollable rather than broken.
class NyChipBar extends StatefulWidget {
  const NyChipBar({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: NySpacing.gutter),
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  State<NyChipBar> createState() => _NyChipBarState();
}

class _NyChipBarState extends State<NyChipBar> {
  final ScrollController _controller = ScrollController();
  bool _atEnd = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final atEnd = _controller.offset >=
        _controller.position.maxScrollExtent - 4;
    if (atEnd != _atEnd) setState(() => _atEnd = atEnd);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            Colors.white,
            Colors.white,
            _atEnd ? Colors.white : Colors.white.withValues(alpha: 0),
          ],
          stops: const <double>[0.0, 0.88, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: widget.padding,
          itemCount: widget.labels.length,
          separatorBuilder: (_, _) => const SizedBox(width: NySpacing.space8),
          itemBuilder: (context, i) => NyFilterPill(
            label: widget.labels[i],
            selected: i == widget.selectedIndex,
            onTap: () => widget.onSelected(i),
          ),
        ),
      ),
    );
  }
}

/// A single filter pill. Selected state fills with the accent gradient.
class NyFilterPill extends StatelessWidget {
  const NyFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = selected
        ? Colors.white
        : theme.colorScheme.onSurface.withValues(alpha: 0.78);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: NyMotion.fast,
          curve: NyMotion.settle,
          padding: const EdgeInsets.symmetric(
            horizontal: NySpacing.space16,
            vertical: NySpacing.space8,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: NyColors.accentGradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: selected
                ? null
                : (isDark
                    ? NyColors.glassFillDark
                    : NyColors.glassFillLight),
            borderRadius: NyRadius.borderPill,
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : (isDark
                      ? NyColors.glassEdgeTopDark
                      : NyColors.borderLight),
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: NyColors.accentGradient[1]
                          .withValues(alpha: 0.36),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: NySpacing.space6),
              ],
              // Flexible so a long label inside a Wrap ellipsises instead of
              // overflowing the pill.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NyTypography.labelMedium.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Equal-width segmented control for two-to-four mutually exclusive modes.
class NySegmented extends StatelessWidget {
  const NySegmented({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.icons,
    super.key,
  });

  final List<String> labels;
  final List<IconData>? icons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(NySpacing.space4),
      decoration: BoxDecoration(
        color: isDark
            ? NyColors.glassFillSunkenDark
            : NyColors.glassFillSunkenLight,
        borderRadius: NyRadius.borderPill,
        border: Border.all(
          color: isDark ? NyColors.borderDark : NyColors.borderLight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / labels.length;
          return Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: NyMotion.normal,
                curve: NyMotion.settle,
                left: slot * selectedIndex,
                top: 0,
                bottom: 0,
                width: slot,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: NyColors.accentGradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: NyRadius.borderPill,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: NyColors.accentGradient[1]
                            .withValues(alpha: 0.34),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  for (int i = 0; i < labels.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == selectedIndex,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelected(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: NySpacing.space10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                if (icons != null) ...<Widget>[
                                  Icon(
                                    icons![i],
                                    size: 15,
                                    color: i == selectedIndex
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: NySpacing.space6),
                                ],
                                Flexible(
                                  child: Text(
                                    labels[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: NyTypography.labelMedium.copyWith(
                                      color: i == selectedIndex
                                          ? Colors.white
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
