import 'package:second_brain/features/notes/domain/entities/note.dart';
import 'package:second_brain/features/notes/domain/repositories/notes_repository.dart';

/// Use case to update an existing note
class UpdateNote {
  final NotesRepository repository;

  const UpdateNote(this.repository);

  Future<void> call(Note note) async {
    // Update the updatedAt timestamp
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    await repository.updateNote(updatedNote);
  }
}
