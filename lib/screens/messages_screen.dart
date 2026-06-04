import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'main_shell.dart';
import 'chat_screen.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _Conversation {
  final String id;
  final String name;
  final String initials;
  final Color avatarColor;
  final String lastMessage;
  final String time;
  final int unread;

  const _Conversation({
    this.id = '',
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.lastMessage,
    required this.time,
    required this.unread,
  });
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}

const _avatarColors = [
  Color(0xFF7C3AED),
  Color(0xFF059669),
  Color(0xFFEC4899),
  Color(0xFFFF9100),
  Color(0xFF3B82F6),
];


// ─── Screen ───────────────────────────────────────────────────────────────────

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _controller = TextEditingController();
  String _query = '';
  List<_Conversation> _allConvos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    MainShell.tabNotifier.addListener(_onTabChange);
  }

  @override
  void dispose() {
    MainShell.tabNotifier.removeListener(_onTabChange);
    _controller.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (MainShell.tabNotifier.value == 1 && mounted) {
      _loadConversations();
    }
  }

  Future<void> _loadConversations() async {
    setState(() {
      _allConvos = [];
      _loading = true;
    });
    try {
      final convos = await ApiService.getConversations();
      if (!mounted) return;
      final orgNames = <String, String>{};
      await Future.wait(convos.map((c) async {
        if (c.organizationId.isNotEmpty) {
          try {
            final org = await ApiService.getOrganization(c.organizationId);
            orgNames[c.organizationId] = (org['name'] ?? '').toString();
          } catch (_) {}
        }
      }));
      if (!mounted) return;
      setState(() {
        _allConvos = convos.asMap().entries.map((e) {
          final c = e.value;
          final name = orgNames[c.organizationId] ??
              (c.name.isNotEmpty ? c.name : 'Organization #${c.organizationId}');
          return _Conversation(
            id: c.id,
            name: name,
            initials: _initials(name),
            avatarColor: _avatarColors[e.key % _avatarColors.length],
            lastMessage: c.lastMessage,
            time: c.time,
            unread: c.unreadCount,
          );
        }).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_Conversation> get _filtered {
    if (_query.isEmpty) return _allConvos;
    final q = _query.toLowerCase();
    return _allConvos.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? _buildEmpty()
                      : _buildList(items),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(
            'Messages',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: TextField(
          controller: _controller,
          onChanged: (v) => setState(() => _query = v),
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          cursorColor: AppColors.purple,
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: GoogleFonts.poppins(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<_Conversation> items) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: items.length,
      separatorBuilder: (context, i) => const Divider(
        height: 1,
        color: AppColors.divider,
        indent: 86,
        endIndent: 20,
      ),
      itemBuilder: (context, i) => _ConversationTile(conversation: items[i]),
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
              Icons.chat_bubble_outline_rounded,
              color: AppColors.textMuted,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Messages Yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'You can contact an organizer,\nyour conversations will appear here',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Conversation tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final _Conversation conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unread > 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, _, _) => ChatScreen(
            conversationId:
                conversation.id.isNotEmpty ? conversation.id : null,
            name: conversation.name,
            initials: conversation.initials,
            avatarColor: conversation.avatarColor,
          ),
          transitionsBuilder: (_, animation, _, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: conversation.avatarColor.withValues(alpha: 0.15),
                    border: Border.all(
                      color: conversation.avatarColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      conversation.initials,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: conversation.avatarColor,
                      ),
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.purple,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
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
                          conversation.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        conversation.time,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: hasUnread
                              ? AppColors.purple
                              : AppColors.textMuted,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: hasUnread
                                ? AppColors.textSecondary
                                : AppColors.textMuted,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unread}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
