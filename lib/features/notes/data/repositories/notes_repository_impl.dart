import '../../domain/entities/note.dart';
import '../models/note_model.dart';
import '../datasources/notes_local_datasource.dart';
import '../services/vector_search_service.dart';
import '../../domain/repositories/notes_repository.dart';

class NotesRepositoryImpl implements NotesRepository {
  final NotesLocalDatasource localDatasource;
  final VectorSearchService _vectorSearchService = VectorSearchService();
  List<Note> _notes = [];

  NotesRepositoryImpl(this.localDatasource);

  @override
  Future<List<Note>> getAllNotes() async {
    try {
      final noteModels = await localDatasource.getNotes();
      _notes = List<Note>.from(noteModels);

      // 1. EXTRACT cached embeddings from notes
      final Map<String, List<double>> cachedEmbeddings = {};
      final List<Note> notesMissingEmbeddings = [];

      for (final note in _notes) {
        if (note.embedding != null && note.embedding!.isNotEmpty) {
          cachedEmbeddings[note.id] = note.embedding!;
        } else {
          notesMissingEmbeddings.add(note);
        }
      }

      // 2. HYDRATE the service instantly (Fast!)
      _vectorSearchService.hydrateEmbeddings(cachedEmbeddings);

      // 3. REPAIR missing embeddings in background (Slow, but rare)
      if (notesMissingEmbeddings.isNotEmpty) {
        _repairMissingEmbeddings(notesMissingEmbeddings);
      }

      return _notes;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> createNote(Note note) async {
    // 1. Save note immediately (UI feels fast)
    _notes.add(note);
    await _saveToDisk();

    // 2. Generate embedding in background
    final vector = await _vectorSearchService.upsertEmbedding(
        note.id, '${note.title} ${note.content}');

    // 3. If successful, UPDATE the note with the new embedding and save again
    if (vector != null) {
      final updatedNote = note.copyWith(embedding: vector);
      final idx = _notes.indexWhere((n) => n.id == note.id);
      if (idx != -1) {
        _notes[idx] = updatedNote;
        await _saveToDisk(); // Save the "Brain" to disk!
      }
    }
  }

  @override
  Future<void> updateNote(Note note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      _notes[idx] = note;
      await _saveToDisk();

      // Regenerate embedding
      final vector = await _vectorSearchService.upsertEmbedding(
          note.id, '${note.title} ${note.content}');

      if (vector != null) {
        final updatedNote = note.copyWith(embedding: vector);
        _notes[idx] = updatedNote;
        await _saveToDisk();
      }
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    await _saveToDisk();
    _vectorSearchService.removeEmbedding(noteId);
  }

  // ... (getNoteById, searchNotes, semanticSearchNotes remain the same)
  @override
  Future<Note?> getNoteById(String noteId) async {
    for (final n in _notes) {
      if (n.id == noteId) return n;
    }
    return null;
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
    final results = await _vectorSearchService.search(query, topN: topN);
    final List<Note> foundNotes = [];
    for (final entry in results) {
      final note = await getNoteById(entry.key);
      if (note != null) foundNotes.add(note);
    }
    return foundNotes;
  }

  Future<void> _saveToDisk() async {
    final models = _notes.map((n) => NoteModel.fromEntity(n)).toList();
    await localDatasource.saveNotes(models);
  }

  Future<void> _repairMissingEmbeddings(List<Note> notes) async {
    for (final note in notes) {
      final vector = await _vectorSearchService.upsertEmbedding(
          note.id, '${note.title} ${note.content}');

      if (vector != null) {
        final idx = _notes.indexWhere((n) => n.id == note.id);
        if (idx != -1) {
          _notes[idx] = note.copyWith(embedding: vector);
          await _saveToDisk();
        }
      }
    }
  }
}