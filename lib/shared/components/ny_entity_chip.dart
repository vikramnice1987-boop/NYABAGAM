import 'package:flutter/material.dart';
import '../../core/theme/ny_colors.dart';
import '../../core/theme/ny_radius.dart';
import '../../core/theme/ny_spacing.dart';

enum NyEntityType { person, organization, thing, place, event, general }

class NyEntityChip extends StatelessWidget {
  const NyEntityChip({
    required this.label,
    required this.type,
    this.onTap,
    this.onDeleted,
    super.key,
  });

  final String label;
  final NyEntityType type;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

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
        return NyColors.accentLight;
    }
  }

  IconData get _icon {
    switch (type) {
      case NyEntityType.person:
        return Icons.person_outline;
      case NyEntityType.organization:
        return Icons.business_outlined;
      case NyEntityType.thing:
        return Icons.inventory_2_outlined;
      case NyEntityType.place:
        return Icons.place_outlined;
      case NyEntityType.event:
        return Icons.event_outlined;
      case NyEntityType.general:
        return Icons.label_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = _color;
    return Material(
      color: chipColor.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: NyRadius.borderPill,
        side: BorderSide(color: chipColor.withAlpha(80)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: NyRadius.borderPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: NySpacing.space8, vertical: NySpacing.space4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: 14, color: chipColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: chipColor,
                ),
              ),
              if (onDeleted != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDeleted,
                  child: Icon(Icons.close, size: 14, color: chipColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}