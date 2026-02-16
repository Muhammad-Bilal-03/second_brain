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

// NEW: Use Notifier instead of StateNotifier
class ChatNotifier extends Notifier<List<ChatMessage>> {
  late final RAGService _ragService;
  final _uuid = const Uuid();

  @override
  List<ChatMessage> build() {
    _ragService = ref.read(ragServiceProvider);
    return []; // Initial state
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add User Message
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];

    // 2. Add "Thinking..." message
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

    // 4. Update the "Thinking..." message
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

// NEW: NotifierProvider instead of StateNotifierProvider
final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);