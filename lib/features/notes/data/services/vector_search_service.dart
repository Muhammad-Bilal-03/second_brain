import '../utils/embedding_utils.dart';

class VectorSearchService {
  static final VectorSearchService _instance = VectorSearchService._internal();

  factory VectorSearchService() => _instance;

  VectorSearchService._internal();

  // Map: noteId -> embedding vector
  final Map<String, List<double>> _embeddings = {};

  /// Add or update embedding (Async/Network)
  Future<List<double>?> upsertEmbedding(String noteId, String text) async {
    try {
      final vector = await EmbeddingUtils.embed(text);
      if (vector.isNotEmpty) {
        _embeddings[noteId] = vector;
        return vector; // Return it so we can save it to disk!
      }
    } catch (e) {
      print("Embedding Error: $e");
    }
    return null;
  }

  /// NEW: Load pre-calculated embeddings (Instant/Offline)
  void hydrateEmbeddings(Map<String, List<double>> cache) {
    _embeddings.addAll(cache);
    print("🧠 AI Brain hydrated with ${_embeddings.length} memories from disk.");
  }

  void removeEmbedding(String noteId) {
    _embeddings.remove(noteId);
  }

  Future<List<MapEntry<String, double>>> search(String query, {int topN = 10}) async {
    final queryVec = await EmbeddingUtils.embed(query);
    if (queryVec.isEmpty) return [];

    final scored = _embeddings.entries
        .map((e) => MapEntry(
        e.key,
        EmbeddingUtils.cosineSimilarity(e.value, queryVec)))
        .where((e) => e.value > 0)
        .toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(topN).toList();
  }
}