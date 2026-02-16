import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:second_brain/features/notes/domain/repositories/notes_repository.dart';

class RAGService {
  final NotesRepository notesRepository;
  GenerativeModel? _chatModel;

  RAGService(this.notesRepository);

  /// Initialize the Chat Model (Using Flash for speed)
  GenerativeModel _getModel() {
    if (_chatModel != null) return _chatModel!;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) throw Exception('API Key missing');

    _chatModel = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
    );
    return _chatModel!;
  }

  /// The RAG Workflow
  Future<String> answerQuestion(String query) async {
    try {
      // 1. RETRIEVE: Find relevant notes
      final relevantNotes = await notesRepository.semanticSearchNotes(query, topN: 3);

      // 2. AUGMENT: Construct the context string
      String contextText = "";
      if (relevantNotes.isNotEmpty) {
        contextText = relevantNotes.map((n) =>
        "Title: ${n.title}\nContent: ${n.content}"
        ).join("\n\n");
      }

      // 3. GENERATE: The "Smart" Prompt
      // We instruct the model to judge relevance itself.
      final prompt = '''
You are a "Second Brain" AI assistant. You help the user manage their notes and ideas.

I will provide you with some notes from the user's database that MIGHT be relevant.
--- POTENTIAL CONTEXT ---
${contextText.isEmpty ? "No notes found." : contextText}
-------------------------

INSTRUCTIONS:
1. If the notes above contain the answer to the user's question, use them to answer accurately.
2. If the notes are NOT relevant (e.g., the user is saying "Hello" or asking a general question not in the notes), IGNORE the notes and answer as a helpful AI assistant.
3. Do not make up facts about the user's data. If asked about a specific note that isn't there, say "I couldn't find that in your notes."

User Question: $query
''';

      // 4. Send to Gemini
      final model = _getModel();
      final response = await model.generateContent([Content.text(prompt)]);

      return response.text ?? "I couldn't generate an answer.";

    } catch (e) {
      return "Error generating answer: $e";
    }
  }
}