import 'package:flutter/material.dart';
import '../../core/theme/ny_spacing.dart';
import 'ny_card.dart';

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
        return Icons.mic_none_outlined;
      case 'document':
        return Icons.description_outlined;
      case 'image':
        return Icons.photo_outlined;
      default:
        return Icons.notes_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(NySpacing.space12),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_sourceIcon, size: 14, color: theme.colorScheme.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Evidence Source · $title',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (date != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${date!.day}/${date!.month}/${date!.year}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '"$snippet"',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.textTheme.bodyMedium?.color?.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }
}