import '../utils/embedding_utils.dart';

/// Singleton service to manage and search note embeddings in memory.
class VectorSearchService {
  static final VectorSearchService _instance = VectorSearchService._internal();

  factory VectorSearchService() => _instance;

  VectorSearchService._internal();

  // Map: noteId -> embedding vector
  final Map<String, List<double>> _embeddings = {};

  /// Add or update embedding for a note
  void upsertEmbedding(String noteId, String text) {
    _embeddings[noteId] = EmbeddingUtils.embed(text);
  }

  /// Remove embedding for a note
  void removeEmbedding(String noteId) {
    _embeddings.remove(noteId);
  }

  /// Bulk replace all embeddings (e.g. on app start)
  void rebuildEmbeddings(Map<String, String> noteTexts) {
    _embeddings
      ..clear()
      ..addEntries(noteTexts.entries.map(
              (e) => MapEntry(e.key, EmbeddingUtils.embed(e.value))));
  }

  /// Semantic search: returns top N noteIds for query string
  List<MapEntry<String, double>> search(String query, {int topN = 10}) {
    final queryVec = EmbeddingUtils.embed(query);
    final scored = _embeddings.entries
        .map((e) => MapEntry(
        e.key, EmbeddingUtils.cosineSimilarity(e.value, queryVec)))
        .where((e) => e.value > 0) // skip zero similarity
        .toList();
    scored.sort((a, b) => b.value.compareTo(a.value)); // highest first
    return scored.take(topN).toList();
  }
}