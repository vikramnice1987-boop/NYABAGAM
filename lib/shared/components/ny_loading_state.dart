import 'package:flutter/material.dart';
import '../../core/theme/ny_spacing.dart';

class NyLoadingState extends StatelessWidget {
  const NyLoadingState({this.message = 'Loading...', super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: NySpacing.space16),
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}