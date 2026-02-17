import 'package:flutter/material.dart';
import 'package:second_brain/features/notes/domain/entities/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    this.isSelected = false, // Default false
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Default surface color (clean look)
    final bgColor = theme.colorScheme.surfaceContainer;

    return Stack(
      children: [
        Card(
          color: bgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? BorderSide(color: theme.colorScheme.primary, width: 3) // Thick border when selected
                : BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Pin
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          note.title.isEmpty ? 'Untitled' : note.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.isPinned)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.push_pin, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Content preview
                  if (note.content.isNotEmpty) ...[
                    Text(
                      note.content,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Type Indicator (Optional)
                  if (note.type == 'voice')
                    const Icon(Icons.mic, size: 16, color: Colors.grey)
                  else if (note.type == 'checklist')
                    const Icon(Icons.check_box_outlined, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),

        // Selection Checkmark Overlay
        if (isSelected)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 20, color: Colors.white),
            ),
          ),
      ],
    );
  }
}