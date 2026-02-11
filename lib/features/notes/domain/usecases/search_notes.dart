import 'package:second_brain/features/notes/domain/entities/note.dart';
import 'package:second_brain/features/notes/domain/repositories/notes_repository.dart';

/// Use case to search notes by query string
class SearchNotes {
  final NotesRepository repository;

  const SearchNotes(this.repository);

  Future<List<Note>> call(String query) async {
    if (query.trim().isEmpty) {
      // If query is empty, return all notes
      final notes = await repository.getAllNotes();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    }
    
    final notes = await repository.searchNotes(query);
    // Sort by updatedAt, newest first
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }
}
