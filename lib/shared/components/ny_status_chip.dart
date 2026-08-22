import 'package:flutter/material.dart';

import '../../core/theme/ny_colors.dart';
import '../../core/theme/ny_radius.dart';
import '../../core/theme/ny_spacing.dart';
import '../../core/theme/ny_typography.dart';

/// Small status pill with a luminous dot.
///
/// The dot carries a soft glow in its own colour, which is what keeps a 10px
/// label readable against a busy wallpaper without shouting.
class NyStatusChip extends StatelessWidget {
  const NyStatusChip({
    required this.status,
    super.key,
  });

  final String status;

  Color get _color {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'confirmed':
      case 'active':
      case 'completed':
        return NyColors.statusSuccess;
      case 'needs_service':
      case 'broken':
      case 'failed':
      case 'expired':
        return NyColors.statusError;
      case 'candidate':
      case 'proposed':
      case 'pending':
      case 'expiring_soon':
        return NyColors.statusWarning;
      default:
        return NyColors.statusInfo;
    }
  }

  String get _label => status.replaceAll('_', ' ').toUpperCase();

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NySpacing.space10,
        vertical: NySpacing.space4,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: NyRadius.borderPill,
        border: Border.all(color: c.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(color: c.withValues(alpha: 0.8), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: NySpacing.space6),
          Text(_label, style: NyTypography.labelSmall.copyWith(color: c)),
        ],
      ),
    );
  }
}
