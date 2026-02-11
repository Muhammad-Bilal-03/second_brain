import 'package:second_brain/features/notes/domain/entities/note.dart';
import 'package:second_brain/features/notes/domain/repositories/notes_repository.dart';

/// Use case to get all notes sorted by updatedAt (newest first)
class GetAllNotes {
  final NotesRepository repository;

  const GetAllNotes(this.repository);

  Future<List<Note>> call() async {
    final notes = await repository.getAllNotes();
    // Sort by updatedAt, newest first
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }
}
