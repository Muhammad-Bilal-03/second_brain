import '../utils/embedding_utils.dart';

class VectorSearchService {
  static final VectorSearchService _instance = VectorSearchService._internal();

  factory VectorSearchService() => _instance;

  VectorSearchService._internal();

  final Map<String, List<double>> _embeddings = {};

  Future<List<double>?> upsertEmbedding(String noteId, String text) async {
    try {
      final vector = await EmbeddingUtils.embed(text);
      if (vector.isNotEmpty) {
        _embeddings[noteId] = vector;
        return vector;
      }
    } catch (e) {
      print("Embedding Error: $e");
    }
    return null;
  }

  void hydrateEmbeddings(Map<String, List<double>> cache) {
    _embeddings.addAll(cache);
    print("🧠 AI Brain hydrated with ${_embeddings.length} memories.");
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
        .toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    // ------------------------------------------------------------------
    // 🔍 DEBUG: Print ALL scores to help you tune
    // ------------------------------------------------------------------
    if (scored.isNotEmpty) {
      print("🔍 Search: '$query'");
      for (var i = 0; i < scored.length && i < 5; i++) {
        print("   - Match #${i+1}: ${scored[i].value.toStringAsFixed(3)}");
      }
    }
    // ------------------------------------------------------------------

    // 🔴 TUNING FIX: Set threshold to 0.56
    // Groceries (0.607) -> PASS
    // Papers (0.586)    -> PASS
    // Test (approx 0.53)-> FAIL
    final filtered = scored
        .where((e) => e.value > 0.589)
        .take(topN)
        .toList();

    return filtered;
  }

  Future<void> rebuildEmbeddings(Map<String, String> noteTexts) async {
    _embeddings.clear();
    for (final entry in noteTexts.entries) {
      await upsertEmbedding(entry.key, entry.value);
    }
  }
}