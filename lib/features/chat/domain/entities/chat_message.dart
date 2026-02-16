class ChatMessage {
  final String id;
  final String text;
  final bool isUser; // true = User, false = AI
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}