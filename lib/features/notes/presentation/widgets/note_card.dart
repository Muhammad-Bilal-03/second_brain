import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:second_brain/features/notes/domain/entities/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Detect Note Type
    final bool isChecklist = note.type == 'checklist';
    final bool isCode = note.type == 'code';
    final bool isVoice = note.type == 'voice';

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : (isCode ? const Color(0xFF1E1E1E) : theme.cardTheme.color),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              if (!isDark && !isSelected)
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Title + Type Icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.title.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: 8.0,
                              left: note.isPinned ? 16.0 : 0,
                            ),
                            child: Text(
                              note.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                color: isCode ? Colors.white : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      if (note.title.isEmpty) const Spacer(),
                      // Type Icon Badge
                      _buildTypeIcon(theme, isCode, isVoice, isChecklist),
                    ],
                  ),

                  // Content Preview
                  if (note.content.isNotEmpty || isVoice)
                    _buildContentPreview(theme, isCode, isChecklist, isVoice),
                ],
              ),
            ),
          ),
        ),

        // Pin Icon (Top Left)
        if (note.isPinned)
          Positioned(
            top: 12,
            left: 12,
            child: Icon(
              Icons.push_pin,
              size: 16,
              color: isCode ? Colors.white70 : theme.colorScheme.primary,
            ),
          ),

        // Selection Checkmark (Top Right)
        if (isSelected)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeIcon(ThemeData theme, bool isCode, bool isVoice, bool isChecklist) {
    IconData? icon;
    Color color = theme.disabledColor;

    if (isCode) {
      icon = Icons.code;
      color = Colors.blueAccent;
    } else if (isVoice) {
      icon = Icons.mic;
      color = Colors.redAccent;
    } else if (isChecklist) {
      icon = Icons.check_circle_outline;
      color = Colors.green;
    }

    if (icon == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildContentPreview(ThemeData theme, bool isCode, bool isChecklist, bool isVoice) {
    if (isChecklist) {
      return _buildChecklistPreview(theme, note.content);
    }

    if (isCode) {
      return Text(
        note.content,
        style: GoogleFonts.firaCode(
          color: const Color(0xFFD4D4D4),
          fontSize: 12,
          height: 1.4,
        ),
        maxLines: 8,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (isVoice && note.content.isEmpty) {
      return Row(
        children: [
          Icon(Icons.graphic_eq, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            "Voice Note",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    // Standard Text
    return Text(
      note.content,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
        height: 1.5,
      ),
      maxLines: 8,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildChecklistPreview(ThemeData theme, String content) {
    // Parse first few items to show valid preview
    final lines = content.split('\n').take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        bool isChecked = line.startsWith('- [x]');
        String text = line.replaceAll(RegExp(r'^- \[[ x]\] '), '');

        if (text.trim().isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            children: [
              Icon(
                isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                size: 14,
                color: isChecked ? theme.disabledColor : theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                    color: isChecked ? theme.disabledColor : null,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}