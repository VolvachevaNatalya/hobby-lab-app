import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/org_invite.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class OrganizationInvitesScreen extends StatefulWidget {
  final String orgId;
  final String orgName;

  const OrganizationInvitesScreen({
    super.key,
    required this.orgId,
    required this.orgName,
  });

  @override
  State<OrganizationInvitesScreen> createState() =>
      _OrganizationInvitesScreenState();
}

class _OrganizationInvitesScreenState extends State<OrganizationInvitesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
            _buildTabBar(l10n),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _InviteCodesTab(orgId: widget.orgId),
                  _JoinRequestsTab(orgId: widget.orgId),
                ],
              ),
            ),
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
          Text(
            l10n.invitesAndRequests,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return TabBar(
      controller: _tabs,
      indicatorColor: AppColors.purple,
      indicatorWeight: 2,
      labelColor: AppColors.purpleLight,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle:
          GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400),
      tabs: [
        Tab(text: l10n.inviteCodes),
        Tab(text: l10n.joinRequests),
      ],
    );
  }
}

// ── Invite Codes tab ──────────────────────────────────────────────────────────

class _InviteCodesTab extends StatefulWidget {
  final String orgId;
  const _InviteCodesTab({required this.orgId});

  @override
  State<_InviteCodesTab> createState() => _InviteCodesTabState();
}

class _InviteCodesTabState extends State<_InviteCodesTab> {
  bool _loading = true;
  String? _errorMsg;
  List<OrgInviteCode> _codes = [];

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
      final codes = await ApiService.getInviteCodes(widget.orgId);
      if (mounted) setState(() { _codes = codes; _loading = false; });
    } on Exception catch (e) {
      if (mounted) {
        setState(() { _errorMsg = _parseError(e.toString()); _loading = false; });
      }
    }
  }

  Future<void> _deactivate(OrgInviteCode code) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiService.deactivateInviteCode(widget.orgId, code.id);
      if (!mounted) return;
      messenger.showSnackBar(_successSnack(l10n.codeDeactivatedSuccess));
      _load();
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(_errorSnack(_parseError(e.toString())));
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateInviteSheet(
        orgId: widget.orgId,
        onCreated: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMsg != null) {
      return _ErrorView(message: _errorMsg!, onRetry: _load);
    }
    return Stack(
      children: [
        _codes.isEmpty
            ? _EmptyState(
                icon: Icons.qr_code_rounded,
                message: l10n.noInviteCodesYet,
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: _codes.length,
                itemBuilder: (_, i) => _InviteCodeCard(
                  code: _codes[i],
                  onDeactivate:
                      _codes[i].isActive ? () => _deactivate(_codes[i]) : null,
                ),
              ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: _GradientButton(
            label: l10n.createInviteCode,
            loading: false,
            onTap: _showCreateSheet,
          ),
        ),
      ],
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  final OrgInviteCode code;
  final VoidCallback? onDeactivate;
  const _InviteCodeCard({required this.code, this.onDeactivate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = code.isActive;
    final activeColor =
        isActive ? const Color(0xFF059669) : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.purple.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code.code));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      l10n.codeCopied,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        code.code,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.copy_rounded,
                          size: 15, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              _StatusChip(
                label: isActive ? l10n.activeStatus : l10n.inactiveStatus,
                color: activeColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                icon: Icons.person_rounded,
                label: code.defaultRole == 'admin' ? l10n.roleAdmin : l10n.roleMember,
                color: AppColors.purple,
              ),
              _InfoChip(
                icon: code.requiresApproval
                    ? Icons.pending_rounded
                    : Icons.flash_on_rounded,
                label: code.requiresApproval
                    ? l10n.approvalRequired
                    : l10n.noApprovalRequired,
                color: code.requiresApproval
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF059669),
              ),
              if (code.expiresAt != null)
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label:
                      '${l10n.expiresPrefix} ${_fmtDate(code.expiresAt!)}',
                  color: AppColors.textMuted,
                ),
            ],
          ),
          if (onDeactivate != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onDeactivate,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block_rounded,
                      size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  Text(
                    l10n.deactivateCode,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

// ── Create invite code bottom sheet ───────────────────────────────────────────

class _CreateInviteSheet extends StatefulWidget {
  final String orgId;
  final VoidCallback onCreated;
  const _CreateInviteSheet({required this.orgId, required this.onCreated});

  @override
  State<_CreateInviteSheet> createState() => _CreateInviteSheetState();
}

class _CreateInviteSheetState extends State<_CreateInviteSheet> {
  String _role = 'member';
  bool _requiresApproval = true;
  bool _creating = false;
  String? _errorMsg;

  Future<void> _create() async {
    setState(() { _creating = true; _errorMsg = null; });
    try {
      await ApiService.createInviteCode(
        widget.orgId,
        defaultRole: _role,
        requiresApproval: _requiresApproval,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _creating = false;
          _errorMsg = _parseError(e.toString());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: inset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(
          top: BorderSide(color: AppColors.divider),
          left: BorderSide(color: AppColors.divider),
          right: BorderSide(color: AppColors.divider),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.createInviteCode,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.defaultRoleLabel,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _RoleChip(
                label: l10n.roleMember,
                selected: _role == 'member',
                onTap: () => setState(() => _role = 'member'),
              ),
              const SizedBox(width: 10),
              _RoleChip(
                label: l10n.roleAdmin,
                selected: _role == 'admin',
                onTap: () => setState(() => _role = 'admin'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.requiresApprovalToggle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: _requiresApproval,
                  onChanged: (v) => setState(() => _requiresApproval = v),
                  activeTrackColor: AppColors.purple,
                ),
              ],
            ),
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: _errorMsg!),
          ],
          const SizedBox(height: 24),
          _GradientButton(
            label: l10n.btnCreate,
            loading: _creating,
            onTap: _creating ? null : _create,
          ),
        ],
      ),
    );
  }
}

// ── Join Requests tab ─────────────────────────────────────────────────────────

class _JoinRequestsTab extends StatefulWidget {
  final String orgId;
  const _JoinRequestsTab({required this.orgId});

  @override
  State<_JoinRequestsTab> createState() => _JoinRequestsTabState();
}

class _JoinRequestsTabState extends State<_JoinRequestsTab> {
  bool _loading = true;
  String? _errorMsg;
  List<OrgJoinRequest> _requests = [];

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
      final reqs = await ApiService.getJoinRequests(widget.orgId);
      if (mounted) setState(() { _requests = reqs; _loading = false; });
    } on Exception catch (e) {
      if (mounted) {
        setState(() { _errorMsg = _parseError(e.toString()); _loading = false; });
      }
    }
  }

  Future<void> _approve(OrgJoinRequest req) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiService.approveJoinRequest(widget.orgId, req.id);
      if (!mounted) return;
      messenger.showSnackBar(_successSnack(l10n.requestApprovedSuccess));
      _load();
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(_errorSnack(_parseError(e.toString())));
    }
  }

  Future<void> _reject(OrgJoinRequest req) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiService.rejectJoinRequest(widget.orgId, req.id);
      if (!mounted) return;
      messenger.showSnackBar(_successSnack(l10n.requestRejectedSuccess));
      _load();
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(_errorSnack(_parseError(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_errorMsg != null) return _ErrorView(message: _errorMsg!, onRetry: _load);
    if (_requests.isEmpty) {
      return _EmptyState(
        icon: Icons.inbox_rounded,
        message: l10n.noPendingRequests,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: _requests.length,
      itemBuilder: (_, i) => _JoinRequestCard(
        request: _requests[i],
        onApprove: () => _approve(_requests[i]),
        onReject: () => _reject(_requests[i]),
      ),
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  final OrgJoinRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _JoinRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = request.userName.isNotEmpty ? request.userName : '—';
    final email = request.userEmail.isNotEmpty ? request.userEmail : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (email != null)
                      Text(
                        email,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                _fmtDate(request.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onReject,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            const Color(0xFFEF4444).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        l10n.btnReject,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onApprove,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        l10n.btnApprove,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

// ── Shared helpers ────────────────────────────────────────────────────────────

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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

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
            child: Icon(icon, size: 34, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.5,
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppLocalizations.of(context)!.retryBtn,
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

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _GradientButton(
      {required this.label, required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = onTap != null && !loading;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: active
              ? AppColors.brandGradient
              : const LinearGradient(
                  colors: [Color(0xFF2A2A45), Color(0xFF2A2A45)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
