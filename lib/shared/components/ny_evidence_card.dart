import 'package:flutter/material.dart';

import '../../core/theme/ny_elevation.dart';
import '../../core/theme/ny_radius.dart';
import '../../core/theme/ny_spacing.dart';
import '../../core/theme/ny_typography.dart';
import 'ny_card.dart';

/// A cited source backing an answer.
///
/// Rendered as sunken glass with a luminous rail down the left edge — visually
/// subordinate to the answer it supports, but clearly a distinct, verifiable
/// artifact rather than model prose.
class NyEvidenceCard extends StatelessWidget {
  const NyEvidenceCard({
    required this.title,
    required this.snippet,
    this.sourceType = 'voice',
    this.date,
    this.onTap,
    super.key,
  });

  final String title;
  final String snippet;
  final String sourceType;
  final DateTime? date;
  final VoidCallback? onTap;

  IconData get _sourceIcon {
    switch (sourceType.toLowerCase()) {
      case 'voice':
        return Icons.graphic_eq_rounded;
      case 'document':
        return Icons.description_rounded;
      case 'image':
        return Icons.photo_rounded;
      default:
        return Icons.notes_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;

    return NyCard(
      onTap: onTap,
      level: NyGlassLevel.sunken,
      borderRadius: NyRadius.borderLg,
      blur: false,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Luminous evidence rail.
            Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    accent,
                    accent.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(NySpacing.space14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(_sourceIcon, size: 13, color: accent),
                        const SizedBox(width: NySpacing.space6),
                        Expanded(
                          child: Text(
                            title,
                            style: NyTypography.overline.copyWith(color: accent),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (date != null) ...<Widget>[
                          const SizedBox(width: NySpacing.space8),
                          Text(
                            '${date!.day}/${date!.month}/${date!.year}',
                            style: NyTypography.labelSmall.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: NySpacing.space8),
                    Text(
                      snippet,
                      style: NyTypography.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
