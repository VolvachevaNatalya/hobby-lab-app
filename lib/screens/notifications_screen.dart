import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/app_notification.dart' as model;
import 'main_shell.dart';
import 'notification_details_screen.dart';
import 'notifications_settings_screen.dart';
import 'chat_screen.dart';
import '../routing/transitions.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _NotificationData {
  final String? id;
  final String type;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final bool isRead;
  final String? conversationId;

  const _NotificationData({
    this.id,
    this.type = '',
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    this.conversationId,
  });
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
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifs = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = notifs
            .where((n) =>
                !n.isRead && n.type.toLowerCase() != 'new_organization')
            .map((n) => _toDisplay(n))
            .toList();
      });
    } catch (_) {
    } finally {
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
      time: n.time,
      isRead: n.isRead,
      conversationId: n.conversationId,
    );
  }

  Future<void> _markRead(int index) async {
    final item = _items[index];
    if (item.id == null) return;
    setState(() => _items.removeAt(index));
    try {
      await ApiService.markNotificationRead(item.id!);
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
                            return _NotificationTile(
                              data: item,
                              onTap: () {
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
                                    )));
                                  }
                                } else {
                                  Navigator.of(context).push(slideRoute(builder: (_) => NotificationDetailsScreen(
                                    icon: item.icon,
                                    iconColor: item.iconColor,
                                    title: item.title,
                                    body: item.body,
                                    time: item.time,
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
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              slideRoute(builder: (_) => const NotificationsSettingsScreen()),
            ),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
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
                          data.title,
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
                        data.time,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    data.body,
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
