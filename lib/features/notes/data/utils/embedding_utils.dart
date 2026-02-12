import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmbeddingUtils {
  static GenerativeModel? _model;

  static GenerativeModel _getModel() {
    if (_model != null) return _model!;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('🔴 FATAL: GEMINI_API_KEY is missing in .env!');
      throw Exception('GEMINI_API_KEY not found');
    }

    _model = GenerativeModel(
      model: 'gemini-embedding-001',
      apiKey: apiKey,
    );
    return _model!;
  }

  static Future<List<double>> embed(String text) async {
    if (text.trim().isEmpty) return [];

    try {
      final model = _getModel();
      final content = Content.text(text);
      final result = await model.embedContent(content);

      print('🟢 AI Success: Generated vector for "${text.substring(0, min(20, text.length))}..."');
      return result.embedding.values;
    } catch (e) {
      // THIS IS THE IMPORTANT PART:
      print('🔴 AI ERROR: Could not generate embedding. Reason: $e');
      return [];
    }
  }

  static double cosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) return 0.0;
    if (v1.isEmpty) return 0.0;

    double dot = 0, normA = 0, normB = 0;
    for (var i = 0; i < v1.length; i++) {
      dot += v1[i] * v2[i];
      normA += v1[i] * v1[i];
      normB += v2[i] * v2[i];
    }

    final denominator = sqrt(normA) * sqrt(normB);
    return denominator == 0 ? 0.0 : dot / denominator;
  }
}