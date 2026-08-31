import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';
import '../unread_state.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _Msg {
  final String text;
  final bool isUser;
  final String rawTime;
  const _Msg(this.text, this.isUser, this.rawTime);
}

String _fmtChatTime(String raw, AppLocalizations l10n) {
  if (raw.isEmpty || raw == 'Now') return raw;
  try {
    final dt = DateTime.parse(raw).toLocal();
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
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

// ─── Screen ───────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String name;
  final String initials;
  final Color avatarColor;
  // Counterpart context — set by MessagesScreen; empty when opened from other screens
  final String conversationUserId;
  final String organizationId;

  const ChatScreen({
    super.key,
    this.conversationId,
    required this.name,
    required this.initials,
    required this.avatarColor,
    this.conversationUserId = '',
    this.organizationId = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  List<_Msg> _messages = [];
  bool _loadingMessages = false;
  late String _headerName;
  late String _headerInitials;
  // Resolved at load time; may start empty if caller didn't provide them
  String _conversationUserId = '';
  String _organizationId = '';

  @override
  void initState() {
    super.initState();
    _headerName = widget.name;
    _headerInitials = widget.initials;
    _conversationUserId = widget.conversationUserId;
    _organizationId = widget.organizationId;
    if (widget.conversationId != null) {
      _loadData();
      _markConversationRead();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loadingMessages = true);
    try {
      // getCurrentUserId() is in-memory cached — no extra network call
      final myId = await ApiService.getCurrentUserId();

      // If caller didn't supply conversation context, fetch it now (parallel with messages)
      final needsContext = _conversationUserId.isEmpty || _organizationId.isEmpty;
      final List<dynamic> results = await Future.wait([
        ApiService.getMessages(widget.conversationId!),
        if (needsContext) ApiService.getConversations(),
      ]);

      if (!mounted) return;

      final msgs = results[0] as List<ChatMessage>;

      if (needsContext) {
        final convos = results[1] as List<Conversation>;
        try {
          final convo = convos.firstWhere((c) => c.id == widget.conversationId);
          _conversationUserId = convo.userId;
          _organizationId = convo.organizationId;
          // Update header when caller didn't pre-set the counterpart name
          if (widget.name.isEmpty) {
            final isUserSide = myId == convo.userId;
            final name = isUserSide ? convo.organizationName : convo.userName;
            if (name.isNotEmpty && mounted) {
              setState(() {
                _headerName = name;
                _headerInitials = _computeInitials(name);
              });
            }
          }
        } catch (_) {}
      }

      // Determine which side the current user is on in this conversation
      final isUserSide = _conversationUserId.isNotEmpty
          ? myId == _conversationUserId
          : true; // safe default when context is unavailable

      setState(() {
        _messages = msgs.map((msg) {
          final bool isMine;
          if (msg.senderType.isNotEmpty &&
              _conversationUserId.isNotEmpty &&
              _organizationId.isNotEmpty) {
            // New backend format: use sender_type + sender_id together
            isMine = isUserSide
                ? (msg.senderType == 'user' && msg.senderId == _conversationUserId)
                : (msg.senderType == 'organization' && msg.senderId == _organizationId);
          } else {
            // Legacy rows (no sender_type) or missing context: fall back to
            // comparing sender_id against the current user's own ID
            isMine = msg.senderId == myId;
          }
          return _Msg(msg.content, isMine, msg.time);
        }).toList();
      });
    } catch (e) {
      debugPrint('[Chat] Error loading data: $e');
    } finally {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  Future<void> _markConversationRead() async {
    try {
      await ApiService.markConversationRead(widget.conversationId!);
      UnreadCounts.refresh();
    } catch (_) {}
  }

  static String _computeInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    setState(() => _messages.add(_Msg(text, true, 'Now')));
    _scrollToBottom();

    if (widget.conversationId != null) {
      try {
        await ApiService.sendMessage(widget.conversationId!, text);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Text(
                AppLocalizations.of(context)!.failedToSendMessage,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
              ),
            ),
          );
        }
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: _loadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _ChatBubble(
                        msg: _messages[i],
                        avatarColor: widget.avatarColor,
                        initial: _headerInitials.isNotEmpty ? _headerInitials[0] : '?',
                      ),
                    ),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.avatarColor.withValues(alpha: 0.15),
              border: Border.all(
                color: widget.avatarColor.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _headerInitials.isNotEmpty ? _headerInitials : '?',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _headerName,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: _textController,
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  cursorColor: AppColors.purple,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.typeMessageHint,
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat bubble ──────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final _Msg msg;
  final Color avatarColor;
  final String initial;

  const _ChatBubble({
    required this.msg,
    required this.avatarColor,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor.withValues(alpha: 0.15),
                border: Border.all(color: avatarColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: avatarColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser ? AppColors.brandGradient : null,
                    color: isUser ? null : const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.divider),
                    boxShadow: isUser
                        ? [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    msg.text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  msg.rawTime == 'Now'
                      ? AppLocalizations.of(context)!.timeNow
                      : _fmtChatTime(msg.rawTime, AppLocalizations.of(context)!),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
