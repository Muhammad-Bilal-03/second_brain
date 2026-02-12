import '../../domain/entities/note.dart';
import '../models/note_model.dart';
import '../datasources/notes_local_datasource.dart';
import '../services/vector_search_service.dart';
import '../../domain/repositories/notes_repository.dart';

class NotesRepositoryImpl implements NotesRepository {
  final NotesLocalDatasource localDatasource;
  final VectorSearchService _vectorSearchService = VectorSearchService();

  // In-memory cache
  List<Note> _notes = [];

  NotesRepositoryImpl(this.localDatasource);

  @override
  Future<List<Note>> getAllNotes() async {
    try {
      final noteModels = await localDatasource.getNotes();
      _notes = noteModels;
      // Rebuild "Brain" in background
      _rebuildNoteEmbeddings(_notes);
      return _notes;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> createNote(Note note) async {
    _notes.add(note);
    await _saveToDisk();
    await _upsertNoteEmbedding(note);
  }

  @override
  Future<Note?> getNoteById(String noteId) async {
    for (final n in _notes) {
      if (n.id == noteId) return n;
    }
    return null;
  }

  @override
  Future<void> updateNote(Note note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      _notes[idx] = note;
      await _saveToDisk();
      await _upsertNoteEmbedding(note);
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    await _saveToDisk();
    _vectorSearchService.removeEmbedding(noteId);
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    return _notes.where(
            (n) => n.title.toLowerCase().contains(query.toLowerCase()) ||
            n.content.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  @override
  Future<List<Note>> semanticSearchNotes(String query, {int topN = 10}) async {
    // FIX: Directly use service to avoid circular dependency and unused import
    final results = await _vectorSearchService.search(query, topN: topN);

    final List<Note> foundNotes = [];
    for (final entry in results) {
      final note = await getNoteById(entry.key);
      if (note != null) {
        foundNotes.add(note);
      }
    }
    return foundNotes;
  }

  Future<void> _saveToDisk() async {
    final models = _notes.map((n) => NoteModel.fromEntity(n)).toList();
    await localDatasource.saveNotes(models);
  }

  Future<void> _rebuildNoteEmbeddings(List<Note> notes) async {
    final noteTexts = { for (final n in notes) n.id: '${n.title} ${n.content}' };
    await _vectorSearchService.rebuildEmbeddings(noteTexts);
  }

  Future<void> _upsertNoteEmbedding(Note note) async {
    await _vectorSearchService.upsertEmbedding(note.id, '${note.title} ${note.content}');
  }
}