import 'package:second_brain/features/notes/domain/entities/note.dart';

/// Abstract repository for notes operations
abstract class NotesRepository {
  /// Get all notes from storage
  Future<List<Note>> getAllNotes();
  
  /// Get a specific note by ID
  Future<Note?> getNoteById(String id);
  
  /// Create a new note
  Future<void> createNote(Note note);
  
  /// Update an existing note
  Future<void> updateNote(Note note);
  
  /// Delete a note by ID
  Future<void> deleteNote(String id);
  
  /// Search notes by query (searches in title and content)
  Future<List<Note>> searchNotes(String query);
}
