import '../../domain/entities/note.dart';
import '../services/vector_search_service.dart';
import '../../domain/usecases/semantic_search_notes.dart';
import '../../domain/repositories/notes_repository.dart';

class NotesRepositoryImpl implements NotesRepository {
  final List<Note> _notes = [];

  final VectorSearchService _vectorSearchService = VectorSearchService();

  @override
  Future<void> createNote(Note note) async {
    _notes.add(note);
    upsertNoteEmbedding(note);
  }

  @override
  Future<Note?> getNoteById(String noteId) async {
    for (final n in _notes) {
      if (n.id == noteId) return n;
    }
    return null;
  }

  @override
  Future<List<Note>> getAllNotes() async => _notes;

  @override
  Future<void> updateNote(Note note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      _notes[idx] = note;
      upsertNoteEmbedding(note);
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    removeNoteEmbedding(noteId);
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
    rebuildNoteEmbeddings(_notes);
    final semanticUseCase = SemanticSearchNotes(
      repository: this,
      vectorService: _vectorSearchService,
    );
    return await semanticUseCase.call(query, topN: topN);
  }

  // Embedding helpers
  void rebuildNoteEmbeddings(List<Note> notes) {
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