import 'package:second_brain/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:second_brain/features/notes/data/models/note_model.dart';
import 'package:second_brain/features/notes/domain/entities/note.dart';
import 'package:second_brain/features/notes/domain/repositories/notes_repository.dart';

/// Implementation of NotesRepository using local datasource
class NotesRepositoryImpl implements NotesRepository {
  final NotesLocalDatasource localDatasource;

  const NotesRepositoryImpl(this.localDatasource);

  @override
  Future<List<Note>> getAllNotes() async {
    try {
      final noteModels = await localDatasource.getNotes();
      return noteModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get notes: $e');
    }
  }

  @override
  Future<Note?> getNoteById(String id) async {
    try {
      final noteModels = await localDatasource.getNotes();
      final noteModel = noteModels.firstWhere(
        (note) => note.id == id,
        orElse: () => throw Exception('Note not found'),
      );
      return noteModel.toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createNote(Note note) async {
    try {
      final noteModels = await localDatasource.getNotes();
      noteModels.add(NoteModel.fromEntity(note));
      await localDatasource.saveNotes(noteModels);
    } catch (e) {
      throw Exception('Failed to create note: $e');
    }
  }

  @override
  Future<void> updateNote(Note note) async {
    try {
      final noteModels = await localDatasource.getNotes();
      final index = noteModels.indexWhere((n) => n.id == note.id);
      
      if (index == -1) {
        throw Exception('Note not found');
      }
      
      noteModels[index] = NoteModel.fromEntity(note);
      await localDatasource.saveNotes(noteModels);
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    try {
      await localDatasource.deleteNote(id);
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    try {
      final noteModels = await localDatasource.getNotes();
      final lowerQuery = query.toLowerCase();
      
      final filteredModels = noteModels.where((note) {
        final titleMatch = note.title.toLowerCase().contains(lowerQuery);
        final contentMatch = note.content.toLowerCase().contains(lowerQuery);
        return titleMatch || contentMatch;
      }).toList();
      
      return filteredModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to search notes: $e');
    }
  }
}
