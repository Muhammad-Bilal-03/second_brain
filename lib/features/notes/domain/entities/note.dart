import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final String type; // 'text', 'checklist', 'code', 'voice'
  final List<double>? embedding;
  final String? language;
  final String? audioPath;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.type = 'text',
    this.embedding,
    this.language,
    this.audioPath,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    String? type,
    List<double>? embedding,
    String? language,
    String? audioPath,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      type: type ?? this.type,
      embedding: embedding ?? this.embedding,
      language: language ?? this.language,
      audioPath: audioPath ?? this.audioPath,
    );
  }

  @override
  List<Object?> get props => [id, title, content, createdAt, updatedAt, isPinned, type, embedding, language, audioPath];
}