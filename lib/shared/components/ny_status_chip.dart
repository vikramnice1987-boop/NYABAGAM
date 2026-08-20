import 'package:flutter/material.dart';
import '../../core/theme/ny_colors.dart';
import '../../core/theme/ny_radius.dart';
import '../../core/theme/ny_spacing.dart';

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
        return NyColors.statusError;
      case 'candidate':
      case 'proposed':
      case 'pending':
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
      padding: const EdgeInsets.symmetric(horizontal: NySpacing.space8, vertical: NySpacing.space2),
      decoration: BoxDecoration(
        color: c.withAlpha(25),
        borderRadius: NyRadius.borderPill,
        border: Border.all(color: c.withAlpha(80)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: c,
        ),
      ),
    );
  }
}