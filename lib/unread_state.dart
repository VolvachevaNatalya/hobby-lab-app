import 'package:flutter/foundation.dart';
import 'services/api_service.dart';

/// Single source of truth for unread badge counts.
/// Both notifiers are updated together from GET /notifications/unread-count.
/// All screens that show a badge listen here instead of making independent API calls.
class UnreadCounts {
  UnreadCounts._();

  static final messageCount = ValueNotifier<int>(0);
  static final alertCount = ValueNotifier<int>(0);

  static Future<void> refresh() async {
    try {
      final data = await ApiService.getUnreadCounts();
      messageCount.value = data['message_count'] ?? 0;
      alertCount.value = data['alert_count'] ?? 0;
    } catch (_) {}
  }
}
