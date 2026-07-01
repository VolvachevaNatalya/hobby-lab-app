import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/org_member.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class OrganizationMembersScreen extends StatefulWidget {
  final String orgId;
  final String orgName;
  final String viewerRole;

  const OrganizationMembersScreen({
    super.key,
    required this.orgId,
    required this.orgName,
    required this.viewerRole,
  });

  @override
  State<OrganizationMembersScreen> createState() =>
      _OrganizationMembersScreenState();
}

class _OrganizationMembersScreenState
    extends State<OrganizationMembersScreen> {
  bool _loading = true;
  String? _errorMsg;
  List<OrgMember> _members = [];

  bool get _isOwner => widget.viewerRole == 'owner';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final members = await ApiService.getOrgMembers(widget.orgId);
      if (mounted) setState(() { _members = members; _loading = false; });
    } on Exception catch (e) {
      if (mounted) {
        setState(() { _errorMsg = _parseError(e.toString()); _loading = false; });
      }
    }
  }

  Future<void> _changeRole(OrgMember member, String newRole) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiService.updateMemberRole(widget.orgId, member.userId, newRole);
      if (!mounted) return;
      messenger.showSnackBar(_successSnack(l10n.memberRoleChangedSuccess));
      _load();
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(_errorSnack(_parseError(e.toString())));
    }
  }

  Future<void> _confirmRemove(OrgMember member) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.removeMemberTitle,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          l10n.removeMemberConfirm(member.name.isNotEmpty ? member.name : member.email),
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.btnCancel,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.removeMember,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService.removeMember(widget.orgId, member.userId);
      if (!mounted) return;
      messenger.showSnackBar(_successSnack(l10n.memberRemovedSuccess));
      _load();
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(_errorSnack(_parseError(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
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
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.membersTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.orgName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_errorMsg != null) {
      return _ErrorView(message: _errorMsg!, onRetry: _load);
    }
    if (_members.isEmpty) {
      return _EmptyState(message: l10n.noMembersFound);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: _members.length,
      itemBuilder: (_, i) {
        final member = _members[i];
        return _MemberTile(
          member: member,
          onMakeAdmin: (_isOwner && member.role == 'member')
              ? () => _changeRole(member, 'admin')
              : null,
          onMakeMember: (_isOwner && member.role == 'admin')
              ? () => _changeRole(member, 'member')
              : null,
          onRemove: (_isOwner && member.role == 'member')
              ? () => _confirmRemove(member)
              : null,
        );
      },
    );
  }
}

// ── Member tile ───────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final OrgMember member;
  final VoidCallback? onMakeAdmin;
  final VoidCallback? onMakeMember;
  final VoidCallback? onRemove;

  const _MemberTile({
    required this.member,
    this.onMakeAdmin,
    this.onMakeMember,
    this.onRemove,
  });

  bool get _hasActions =>
      onMakeAdmin != null || onMakeMember != null || onRemove != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName =
        member.name.isNotEmpty ? member.name : member.email;

    return GestureDetector(
      onLongPress: _hasActions ? () => _showActionSheet(context, l10n) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            _Avatar(name: displayName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (member.email.isNotEmpty && member.name.isNotEmpty)
                    Text(
                      member.email,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _RoleBadge(role: member.role),
            if (_hasActions) ...[
              const SizedBox(width: 4),
              PopupMenuButton<_MemberAction>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted, size: 20),
                color: AppColors.surfaceElevated,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (action) {
                  switch (action) {
                    case _MemberAction.makeAdmin:
                      onMakeAdmin?.call();
                    case _MemberAction.makeMember:
                      onMakeMember?.call();
                    case _MemberAction.remove:
                      onRemove?.call();
                  }
                },
                itemBuilder: (_) => [
                  if (onMakeAdmin != null)
                    PopupMenuItem(
                      value: _MemberAction.makeAdmin,
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded,
                              size: 18, color: AppColors.purple),
                          const SizedBox(width: 10),
                          Text(l10n.makeAdmin,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  if (onMakeMember != null)
                    PopupMenuItem(
                      value: _MemberAction.makeMember,
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Text(l10n.makeMember,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  if (onRemove != null)
                    PopupMenuItem(
                      value: _MemberAction.remove,
                      child: Row(
                        children: [
                          const Icon(Icons.person_remove_rounded,
                              size: 18, color: Color(0xFFEF4444)),
                          const SizedBox(width: 10),
                          Text(l10n.removeMember,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFFEF4444),
                              )),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: AppColors.divider),
            left: BorderSide(color: AppColors.divider),
            right: BorderSide(color: AppColors.divider),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              member.name.isNotEmpty ? member.name : member.email,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (onMakeAdmin != null)
              _SheetAction(
                icon: Icons.admin_panel_settings_rounded,
                label: l10n.makeAdmin,
                color: AppColors.purple,
                onTap: () {
                  Navigator.of(context).pop();
                  onMakeAdmin?.call();
                },
              ),
            if (onMakeMember != null)
              _SheetAction(
                icon: Icons.person_rounded,
                label: l10n.makeMember,
                color: AppColors.textSecondary,
                onTap: () {
                  Navigator.of(context).pop();
                  onMakeMember?.call();
                },
              ),
            if (onRemove != null)
              _SheetAction(
                icon: Icons.person_remove_rounded,
                label: l10n.removeMember,
                color: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.of(context).pop();
                  onRemove?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}

enum _MemberAction { makeAdmin, makeMember, remove }

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  Color get _color {
    switch (role) {
      case 'owner':
        return AppColors.purple;
      case 'admin':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (role) {
      'owner' => l10n.roleOwner,
      'admin' => l10n.roleAdmin,
      _ => l10n.roleMember,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.group_off_rounded,
                size: 34, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _parseError(String raw) {
  if (raw.startsWith('Exception: ')) return raw.substring(11);
  return raw;
}

SnackBar _successSnack(String msg) => SnackBar(
      content: Text(msg,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
      backgroundColor: const Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );

SnackBar _errorSnack(String msg) => SnackBar(
      content: Text(msg,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
