import 'package:flutter/material.dart';

/// Widget shown when there are no notes
class EmptyNotesWidget extends StatelessWidget {
  const EmptyNotesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 100,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No notes yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first note',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
