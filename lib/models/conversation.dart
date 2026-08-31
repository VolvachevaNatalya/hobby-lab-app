class Conversation {
  final String id;
  final String organizationId;
  final String organizationName;
  final String userId;
  final String userName;
  final String lastMessage;
  final String time;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.organizationId,
    this.organizationName = '',
    this.userId = '',
    this.userName = '',
    this.lastMessage = '',
    this.time = '',
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: (json['id'] ?? '').toString(),
      organizationId: (json['organization_id'] ?? '').toString(),
      organizationName: (json['organization_name'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      userName: (json['user_name'] ?? '').toString(),
      lastMessage: (json['last_message'] ?? '').toString(),
      time: (json['last_message_at'] ?? json['created_at'] ?? '').toString(),
      unreadCount: (json['unread_count'] as int?) ?? 0,
    );
  }
}
