import 'package:uuid/uuid.dart';
import 'package:second_brain/features/notes/domain/entities/note.dart';
import 'package:second_brain/features/notes/domain/repositories/notes_repository.dart';

/// Use case to create a new note
class CreateNote {
  final NotesRepository repository;
  final Uuid _uuid = const Uuid();

  CreateNote(this.repository);

  Future<void> call({
    required String title,
    required String content,
    String? color,
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      color: color,
    );
    
    await repository.createNote(note);
  }
}
