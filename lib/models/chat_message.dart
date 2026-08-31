class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final String senderType; // "user" | "organization" | "" for legacy rows
  final String time;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    this.senderType = '',
    required this.time,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      content: (json['message_text'] ?? json['content'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      senderType: (json['sender_type'] ?? '').toString(),
      time: (json['created_at'] ?? '').toString(),
    );
  }
}
