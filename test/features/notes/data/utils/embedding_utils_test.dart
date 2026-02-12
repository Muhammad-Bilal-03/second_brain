import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/notes/data/utils/embedding_utils.dart';

void main() {
  test('Embedding of identical texts should be equal', () {
    final a = EmbeddingUtils.embed('hello world');
    final b = EmbeddingUtils.embed('hello world');
    expect(a, equals(b));
  });

  test('Cosine similarity of identical vectors is 1', () {
    final a = [2.0, 3.0];
    expect(EmbeddingUtils.cosineSimilarity(a, a), equals(1.0));
  });

  test('Cosine similarity of orthogonal vectors is 0', () {
    final a = [1.0, 0.0];
    final b = [0.0, 1.0];
    expect(EmbeddingUtils.cosineSimilarity(a, b), equals(0.0));
  });
}