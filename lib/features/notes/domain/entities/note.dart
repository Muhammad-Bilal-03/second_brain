import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? color; // Keeping for backward compatibility, but won't use in UI
  final List<double>? embedding;
  final bool isPinned;
  final String type; // <--- NEW: 'text', 'checklist', 'voice', 'image'

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    this.embedding,
    this.isPinned = false,
    this.type = 'text', // Default
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    List<double>? embedding,
    bool? isPinned,
    String? type,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      embedding: embedding ?? this.embedding,
      isPinned: isPinned ?? this.isPinned,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [id, title, content, createdAt, updatedAt, color, embedding, isPinned, type];
}