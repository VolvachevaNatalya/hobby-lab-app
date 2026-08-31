import 'dart:convert';

Map<String, dynamic> _parsePayload(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String && raw.isNotEmpty) {
    try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) {}
  }
  return const {};
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String rawTime;
  final String type;
  final String? conversationId;
  final Map<String, dynamic> payload;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.rawTime,
    required this.type,
    this.conversationId,
    this.payload = const {},
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      isRead: json['is_read'] as bool? ?? json['read'] as bool? ?? false,
      rawTime: (json['created_at'] ?? json['time'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      conversationId: json['conversation_id']?.toString(),
      payload: _parsePayload(json['payload']),
    );
  }
}
