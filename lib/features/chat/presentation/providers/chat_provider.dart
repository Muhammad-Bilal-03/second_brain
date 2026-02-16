import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:second_brain/features/notes/presentation/providers/notes_provider.dart';
import 'package:second_brain/features/chat/data/services/rag_service.dart';
import 'package:second_brain/features/chat/domain/entities/chat_message.dart';

// Provider for the RAG Service
final ragServiceProvider = Provider<RAGService>((ref) {
  final notesRepo = ref.read(notesRepositoryProvider);
  return RAGService(notesRepo);
});

// The State Notifier for the Chat Screen
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final RAGService _ragService;
  final _uuid = const Uuid();

  ChatNotifier(this._ragService) : super([]);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add User Message immediately
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];

    // 2. Add a temporary "Thinking..." message
    final loadingId = _uuid.v4();
    final loadingMsg = ChatMessage(
      id: loadingId,
      text: "Thinking...",
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = [...state, loadingMsg];

    // 3. Get Answer from AI
    final responseText = await _ragService.answerQuestion(text);

    // 4. Replace "Thinking..." with actual answer
    state = [
      for (final msg in state)
        if (msg.id == loadingId)
          ChatMessage(
            id: loadingId,
            text: responseText,
            isUser: false,
            timestamp: DateTime.now(),
          )
        else
          msg
    ];
  }

  void clearChat() {
    state = [];
  }
}

// The Provider accessible in UI
final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final ragService = ref.watch(ragServiceProvider);
  return ChatNotifier(ragService);
});