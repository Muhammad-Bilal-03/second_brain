import '../../data/services/vector_search_service.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class SemanticSearchNotes {
  final NotesRepository repository;
  final VectorSearchService vectorService;

  SemanticSearchNotes({
    required this.repository,
    required this.vectorService,
  });

  /// Returns list of Notes sorted by semantic similarity (descending)
  Future<List<Note>> call(String query, {int topN = 10}) async {
    final allNotes = await repository.getAllNotes();
    final Map<String, Note> noteMap = {
      for (final n in allNotes) n.id: n
    };

    // Get matching noteIds by similarity
    final entries = vectorService.search(query, topN: topN);

    // Return found Notes in order, fallback to [] if none found
    return entries.isEmpty
        ? []
        : entries
        .where((e) => noteMap.containsKey(e.key))
        .map((e) => noteMap[e.key]!)
        .toList();
  }
}