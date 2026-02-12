import '../utils/embedding_utils.dart';

/// Singleton service to manage and search note embeddings in memory.
class VectorSearchService {
  static final VectorSearchService _instance = VectorSearchService._internal();

  factory VectorSearchService() => _instance;

  VectorSearchService._internal();

  // Map: noteId -> embedding vector
  final Map<String, List<double>> _embeddings = {};

  /// Add or update embedding for a note (Async)
  Future<void> upsertEmbedding(String noteId, String text) async {
    final vector = await EmbeddingUtils.embed(text);
    if (vector.isNotEmpty) {
      _embeddings[noteId] = vector;
    }
  }

  /// Remove embedding for a note
  void removeEmbedding(String noteId) {
    _embeddings.remove(noteId);
  }

  /// Bulk replace all embeddings (e.g. on app start)
  Future<void> rebuildEmbeddings(Map<String, String> noteTexts) async {
    _embeddings.clear();

    // Process sequentially to avoid hitting API rate limits too hard
    // (For production, you'd want a batch processing queue)
    for (final entry in noteTexts.entries) {
      await upsertEmbedding(entry.key, entry.value);
    }
  }

  /// Semantic search: returns top N noteIds for query string
  Future<List<MapEntry<String, double>>> search(String query, {int topN = 10}) async {
    // 1. Get vector for the search query
    final queryVec = await EmbeddingUtils.embed(query);
    if (queryVec.isEmpty) return [];

    // 2. Compare against all stored notes
    final scored = _embeddings.entries
        .map((e) => MapEntry(
        e.key,
        EmbeddingUtils.cosineSimilarity(e.value, queryVec)
    ))
        .where((e) => e.value > 0) // skip zero similarity
        .toList();

    // 3. Sort by highest similarity
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.take(topN).toList();
  }
}