class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String time;
  final String type;
  final String? conversationId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.time,
    required this.type,
    this.conversationId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final raw = (json['created_at'] ?? json['time'] ?? '').toString();
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      isRead: json['is_read'] as bool? ?? json['read'] as bool? ?? false,
      time: _formatTime(raw),
      type: (json['type'] ?? '').toString(),
      conversationId: json['conversation_id']?.toString(),
    );
  }

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${_months[dt.month]} ${dt.day}, $hour:$min';
    } catch (_) {
      return iso;
    }
  }
}
