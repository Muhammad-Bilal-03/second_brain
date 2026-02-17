import 'package:second_brain/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:second_brain/features/notes/data/models/note_model.dart';
import 'package:second_brain/features/notes/data/services/vector_search_service.dart';
import 'package:second_brain/features/notes/domain/entities/note.dart';
import 'package:second_brain/features/notes/domain/repositories/notes_repository.dart';

class NotesRepositoryImpl implements NotesRepository {
  final NotesLocalDatasource localDataSource;
  final VectorSearchService vectorSearchService;

  NotesRepositoryImpl(this.localDataSource, this.vectorSearchService);

  @override
  Future<List<Note>> getNotes() async {
    final noteModels = await localDataSource.getNotes();
    final notes = List<Note>.from(noteModels);

    // Sort: Pinned first, then Newest
    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  @override
  Future<void> saveNote(Note note) async {
    // 1. Save to Hive
    await localDataSource.cacheNote(NoteModel.fromEntity(note));

    // 2. Update Embedding (Background)
    // We do this silently to not block the UI
    _updateEmbedding(note);
  }

  Future<void> _updateEmbedding(Note note) async {
    // Only text content needs embedding
    if (note.content.isEmpty) return;

    final vector = await vectorSearchService.upsertEmbedding(
        note.id, '${note.title} \n ${note.content}');

    if (vector != null) {
      final updatedNote = note.copyWith(embedding: vector);
      await localDataSource.cacheNote(NoteModel.fromEntity(updatedNote));
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    await localDataSource.deleteNote(id);
    vectorSearchService.removeEmbedding(id);
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    final allNotes = await getNotes();
    final q = query.toLowerCase();
    return allNotes.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<List<Note>> semanticSearchNotes(String query, {int topN = 10}) async {
    final results = await vectorSearchService.search(query, topN: topN);
    final allNotes = await getNotes();

    final List<Note> found = [];
    for (var entry in results) {
      try {
        final note = allNotes.firstWhere((n) => n.id == entry.key);
        found.add(note);
      } catch (e) {
        // Note might have been deleted but vector remains
        continue;
      }
    }
    return found;
  }
}