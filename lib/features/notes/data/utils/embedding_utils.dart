import 'dart:math';

class EmbeddingUtils {
  /// Generate a pseudo-embedding for a string (simple hash > mean for demo)
  static List<double> embed(String text) {
    final words = text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return [0.0];

    // For a demo: hashCode as float, mean vector
    return [
      words.map((w) => w.hashCode.toDouble()).reduce((a, b) => a + b) /
          words.length
    ];
  }

  /// Standard cosine similarity between two vectors
  static double cosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) return 0.0;
    double dot = 0, normA = 0, normB = 0;
    for (var i = 0; i < v1.length; i++) {
      dot += v1[i] * v2[i];
      normA += v1[i] * v1[i];
      normB += v2[i] * v2[i];
    }
    return (sqrt(normA) * sqrt(normB)) == 0 ? 0.0 : dot / (sqrt(normA) * sqrt(normB));
  }
}