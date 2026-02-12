import '../../domain/entities/note.dart';
import '../models/note_model.dart';
import '../datasources/notes_local_datasource.dart';
import '../services/vector_search_service.dart';
import '../../domain/usecases/semantic_search_notes.dart';
import '../../domain/repositories/notes_repository.dart';

class NotesRepositoryImpl implements NotesRepository {
  final NotesLocalDatasource localDatasource; // Dependency
  final VectorSearchService _vectorSearchService = VectorSearchService();

  // In-memory cache for speed
  List<Note> _notes = [];

  // Inject Datasource in Constructor
  NotesRepositoryImpl(this.localDatasource);

  @override
  Future<List<Note>> getAllNotes() async {
    try {
      // 1. Load from Disk (Isar/SharedPrefs)
      final noteModels = await localDatasource.getNotes();
      _notes = noteModels;

      // 2. IMPORTANT: Restore the "Second Brain" (Embeddings)
      // Since embeddings are in-memory, we must rebuild them whenever we load from disk.
      rebuildNoteEmbeddings(_notes);

      return _notes;
    } catch (e) {
      // Handle error or return empty
      return [];
    }
  }

  @override
  Future<void> createNote(Note note) async {
    // 1. Add to Memory
    _notes.add(note);

    // 2. Save to Disk
    await _saveToDisk();

    // 3. Update AI
    upsertNoteEmbedding(note);
  }

  @override
  Future<void> updateNote(Note note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      _notes[idx] = note;
      await _saveToDisk(); // Save changes
      upsertNoteEmbedding(note);
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    await _saveToDisk(); // Save changes
    removeNoteEmbedding(noteId);
  }

  /// Helper to persist the current _notes list to Datasource
  Future<void> _saveToDisk() async {
    // Convert entities back to models for storage
    final models = _notes.map((n) => NoteModel.fromEntity(n)).toList();
    await localDatasource.saveNotes(models);
  }

  // --- Search Implementation ---

  @override
  Future<Note?> getNoteById(String noteId) async {
    // We can just check our memory cache
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
    // Ensure embeddings are fresh (optional safety check)
    if (_notes.isNotEmpty) {
      rebuildNoteEmbeddings(_notes);
    }

    final semanticUseCase = SemanticSearchNotes(
      repository: this,
      vectorService: _vectorSearchService,
    );
    return await semanticUseCase.call(query, topN: topN);
  }

  // Embedding helpers
  void rebuildNoteEmbeddings(List<Note> notes) {
    // Create map of ID -> "Title + Content"
    final noteTexts = { for (final n in notes) n.id: '${n.title} ${n.content}' };
    _vectorSearchService.rebuildEmbeddings(noteTexts);
  }

  void upsertNoteEmbedding(Note note) {
    _vectorSearchService.upsertEmbedding(note.id, '${note.title} ${note.content}');
  }

  void removeNoteEmbedding(String id) {
    _vectorSearchService.removeEmbedding(id);
  }
}