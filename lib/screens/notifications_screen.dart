import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/app_notification.dart' as model;
import 'main_shell.dart';
import 'notification_details_screen.dart';
import 'event_details_screen.dart';
import 'chat_screen.dart';
import '../routing/transitions.dart';
import '../unread_state.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _NotificationData {
  final String? id;
  final String type;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String rawTime;
  final bool isRead;
  final String? conversationId;
  final Map<String, dynamic> payload;

  const _NotificationData({
    this.id,
    this.type = '',
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.rawTime,
    required this.isRead,
    this.conversationId,
    this.payload = const {},
  });
}

String _fmtNotifTime(String raw, AppLocalizations l10n) {
  if (raw.isEmpty) return '';
  try {
    final dt = DateTime.parse(raw).toLocal();
    final now = DateTime.now();
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) return '$hour:$min';
    final months = [
      l10n.monthJanAbbrev, l10n.monthFebAbbrev, l10n.monthMarAbbrev,
      l10n.monthAprAbbrev, l10n.monthMayAbbrev, l10n.monthJunAbbrev,
      l10n.monthJulAbbrev, l10n.monthAugAbbrev, l10n.monthSepAbbrev,
      l10n.monthOctAbbrev, l10n.monthNovAbbrev, l10n.monthDecAbbrev,
    ];
    return '${months[dt.month - 1]} ${dt.day}, $hour:$min';
  } catch (_) {
    return raw;
  }
}


String _resolveNotifText(String raw, AppLocalizations l10n) {
  switch (raw) {
    case 'notification.new_message.title': return l10n.notifNewMessageTitle;
    case 'notification.new_message.body':  return l10n.notifNewMessageBody;
    default: return raw;
  }
}

String _titleForItem(_NotificationData data, AppLocalizations l10n) {
  switch (data.type) {
    case 'event_updated': return l10n.notifEventUpdatedTitle;
    case 'event_cancelled': return l10n.notifEventCancelledTitle;
    case 'new_event': return l10n.notifNewEventTitle;
    default: return _resolveNotifText(data.title, l10n);
  }
}

String _bodyForItem(_NotificationData data, AppLocalizations l10n) {
  final eventTitle = (data.payload['event_title'] as String?) ?? '';
  final orgName = (data.payload['organization_name'] as String?) ?? '';
  switch (data.type) {
    case 'event_updated': return l10n.notifEventUpdatedBody(eventTitle);
    case 'event_cancelled': return l10n.notifEventCancelledBody(eventTitle);
    case 'new_event': return l10n.notifNewEventBody(orgName, eventTitle);
    default: return _resolveNotifText(data.body, l10n);
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_NotificationData> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    MainShell.tabNotifier.addListener(_onTabChange);
    _loadNotifications();
  }

  @override
  void dispose() {
    MainShell.tabNotifier.removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() {
    if (MainShell.tabNotifier.value == 3 && mounted) {
      _loadNotifications(silent: true);
      UnreadCounts.refresh();
    }
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent || _items.isEmpty) setState(() => _loading = true);
    try {
      final notifs = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = notifs
            .where((n) =>
                !n.isRead &&
                n.type.toLowerCase() != 'new_organization' &&
                n.type.toLowerCase() != 'message')
            .map((n) => _toDisplay(n))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static _NotificationData _toDisplay(model.AppNotification n) {
    IconData icon;
    Color color;
    switch (n.type.toLowerCase()) {
      case 'booking':
        icon = Icons.check_circle_rounded;
        color = const Color(0xFF059669);
        break;
      case 'message':
        icon = Icons.chat_bubble_rounded;
        color = const Color(0xFF7C3AED);
        break;
      case 'offer':
      case 'promotion':
        icon = Icons.local_offer_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'new_activity':
        icon = Icons.explore_rounded;
        color = const Color(0xFFEC4899);
        break;
      case 'event_updated':
        icon = Icons.edit_calendar_rounded;
        color = const Color(0xFF0EA5E9);
        break;
      case 'event_cancelled':
        icon = Icons.event_busy_rounded;
        color = const Color(0xFFEF4444);
        break;
      case 'new_event':
        icon = Icons.event_rounded;
        color = const Color(0xFF10B981);
        break;
      default:
        icon = Icons.notifications_rounded;
        color = const Color(0xFF0EA5E9);
    }
    return _NotificationData(
      id: n.id,
      type: n.type.toLowerCase(),
      icon: icon,
      iconColor: color,
      title: n.title,
      body: n.body,
      rawTime: n.rawTime,
      isRead: n.isRead,
      conversationId: n.conversationId,
      payload: n.payload,
    );
  }

  Future<void> _markRead(int index) async {
    final item = _items[index];
    if (item.id == null) return;
    setState(() => _items.removeAt(index));
    try {
      await ApiService.markNotificationRead(item.id!);
      UnreadCounts.refresh();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 8, bottom: 32),
                          itemCount: _items.length,
                          separatorBuilder: (context, i) => const Divider(
                            height: 1,
                            color: AppColors.divider,
                            indent: 72,
                            endIndent: 20,
                          ),
                          itemBuilder: (context, i) {
                            final item = _items[i];
                            final l10n = AppLocalizations.of(context)!;
                            return _NotificationTile(
                              data: item,
                              onTap: () async {
                                _markRead(i);
                                if (item.type == 'message') {
                                  final convId = item.conversationId;
                                  if (convId != null && convId.isNotEmpty) {
                                    final nav = Navigator.of(context);
                                    MainShell.switchTab(1);
                                    nav.pop();
                                    nav.push(slideRoute(builder: (_) => ChatScreen(
                                      conversationId: convId,
                                      name: '',
                                      initials: '?',
                                      avatarColor: item.iconColor,
                                      conversationUserId: '',
                                      organizationId: '',
                                    )));
                                  }
                                } else if (item.type == 'event_updated' ||
                                           item.type == 'event_cancelled' ||
                                           item.type == 'new_event') {
                                  final eventId = item.payload['event_id']?.toString() ?? '';
                                  if (eventId.isEmpty) return;
                                  final nav = Navigator.of(context);
                                  final messenger = ScaffoldMessenger.of(context);
                                  try {
                                    await ApiService.getEvent(eventId);
                                    if (!mounted) return;
                                    nav.push(slideRoute(
                                      builder: (_) => EventDetailsScreen(eventId: eventId),
                                    ));
                                  } catch (_) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(SnackBar(
                                      backgroundColor: const Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      content: Text(
                                        l10n.notifEventNotAvailable,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ));
                                  }
                                } else {
                                  Navigator.of(context).push(slideRoute(builder: (_) => NotificationDetailsScreen(
                                    icon: item.icon,
                                    iconColor: item.iconColor,
                                    title: _titleForItem(item, l10n),
                                    body: _bodyForItem(item, l10n),
                                    time: _fmtNotifTime(item.rawTime, l10n),
                                  )));
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: AppColors.textMuted,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.noNotifications,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.allCaughtUp,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          if (canPop) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            AppLocalizations.of(context)!.notifications,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification tile ────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final _NotificationData data;
  final VoidCallback? onTap;

  const _NotificationTile({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: data.isRead
            ? Colors.transparent
            : AppColors.purple.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, size: 22, color: data.iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _titleForItem(data, l10n),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: data.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _fmtNotifTime(data.rawTime, l10n),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _bodyForItem(data, l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: data.isRead
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (!data.isRead) ...[
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
