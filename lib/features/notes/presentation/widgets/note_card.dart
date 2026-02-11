import 'package:flutter/material.dart';
import 'package:second_brain/core/utils/extensions.dart';
import 'package:second_brain/features/notes/domain/entities/note.dart';

/// Reusable note card widget
class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Parse color if provided
    Color? accentColor;
    if (note.color != null) {
      try {
        accentColor = Color(int.parse(note.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        accentColor = null;
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: accentColor != null
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: accentColor,
                      width: 4,
                    ),
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  note.title.isEmpty ? 'Untitled' : note.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Content preview
                if (note.content.isNotEmpty) ...[
                  Text(
                    note.content,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Time ago
                Text(
                  note.updatedAt.timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
