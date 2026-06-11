import 'package:flutter/material.dart';

class SectionBlock extends StatelessWidget {
  const SectionBlock({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            child: child,
          ),
        ),
      ],
    );
  }
}
