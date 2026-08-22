import 'package:flutter/material.dart';

import '../../core/theme/ny_colors.dart';
import '../../core/theme/ny_motion.dart';
import '../../core/theme/ny_radius.dart';
import '../../core/theme/ny_spacing.dart';
import '../../core/theme/ny_typography.dart';

enum NyEntityType { person, organization, thing, place, event, general }

/// A tinted glass pill identifying an extracted entity.
///
/// The tint is derived from the entity type and applied to fill, edge, icon
/// and label together, so type is legible from colour alone at a glance.
class NyEntityChip extends StatelessWidget {
  const NyEntityChip({
    required this.label,
    required this.type,
    this.onTap,
    this.onDeleted,
    this.selected = false,
    super.key,
  });

  final String label;
  final NyEntityType type;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final bool selected;

  Color get _color {
    switch (type) {
      case NyEntityType.person:
        return NyColors.entityPerson;
      case NyEntityType.organization:
        return NyColors.entityOrg;
      case NyEntityType.thing:
        return NyColors.entityThing;
      case NyEntityType.place:
        return NyColors.entityPlace;
      case NyEntityType.event:
        return NyColors.entityEvent;
      case NyEntityType.general:
        return NyColors.memoryCyanDark;
    }
  }

  IconData get _icon {
    switch (type) {
      case NyEntityType.person:
        return Icons.person_rounded;
      case NyEntityType.organization:
        return Icons.apartment_rounded;
      case NyEntityType.thing:
        return Icons.inventory_2_rounded;
      case NyEntityType.place:
        return Icons.place_rounded;
      case NyEntityType.event:
        return Icons.event_rounded;
      case NyEntityType.general:
        return Icons.label_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: NyMotion.fast,
      curve: NyMotion.settle,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            c.withValues(alpha: selected ? 0.34 : 0.18),
            c.withValues(alpha: selected ? 0.20 : 0.08),
          ],
        ),
        borderRadius: NyRadius.borderPill,
        border: Border.all(
          color: c.withValues(alpha: selected ? 0.75 : 0.38),
          width: selected ? 1.4 : 1,
        ),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: c.withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: NyRadius.borderPill,
        child: InkWell(
          onTap: onTap,
          borderRadius: NyRadius.borderPill,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NySpacing.space12,
              vertical: NySpacing.space6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(_icon, size: 14, color: isDark ? c : c.withValues(alpha: 0.9)),
                const SizedBox(width: NySpacing.space6),
                Flexible(
                  child: Text(
                    label,
                    style: NyTypography.labelMedium.copyWith(
                      color: isDark ? c : theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (onDeleted != null) ...<Widget>[
                  const SizedBox(width: NySpacing.space6),
                  GestureDetector(
                    onTap: onDeleted,
                    child: Semantics(
                      button: true,
                      label: 'Remove $label',
                      child: Icon(Icons.close_rounded, size: 14, color: c),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
