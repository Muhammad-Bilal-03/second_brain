import 'package:second_brain/features/notes/domain/entities/note.dart';

abstract class NotesRepository {
  Future<List<Note>> getNotes();
  Future<void> saveNote(Note note);
  Future<void> deleteNote(String id);
  Future<List<Note>> searchNotes(String query);
  Future<List<Note>> semanticSearchNotes(String query, {int topN = 10});
}