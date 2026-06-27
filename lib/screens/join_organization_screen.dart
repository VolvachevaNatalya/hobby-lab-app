import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/org_invite.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class JoinOrganizationScreen extends StatefulWidget {
  const JoinOrganizationScreen({super.key});

  @override
  State<JoinOrganizationScreen> createState() =>
      _JoinOrganizationScreenState();
}

class _JoinOrganizationScreenState extends State<JoinOrganizationScreen> {
  final _codeCtrl = TextEditingController();

  bool _verifying = false;
  bool _joining = false;
  String? _errorMsg;

  InviteCodeResolveResult? _resolved;
  bool _done = false;
  bool _joinedDirectly = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  String _parseError(String raw) {
    if (raw.startsWith('Exception: ')) return raw.substring(11);
    return raw;
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _verifying = true;
      _errorMsg = null;
    });
    try {
      final result = await ApiService.resolveInviteCode(code);
      if (mounted) setState(() => _resolved = result);
    } on Exception catch (e) {
      if (mounted) setState(() => _errorMsg = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _join() async {
    final resolved = _resolved!;
    final code = _codeCtrl.text.trim();
    setState(() {
      _joining = true;
      _errorMsg = null;
    });
    try {
      final result = await ApiService.submitJoinRequest(
          resolved.organizationId.toString(), code);
      if (mounted) {
        setState(() {
          _done = true;
          _joinedDirectly = !result.requiresApproval;
        });
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _errorMsg = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _resetToInput() {
    setState(() {
      _resolved = null;
      _errorMsg = null;
    });
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
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: _done
                      ? _buildSuccess(l10n)
                      : _resolved == null
                          ? _buildInputPhase(l10n)
                          : _buildConfirmPhase(l10n),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

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
            l10n.joinOrganization,
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

  // ── Phase 1: code input ───────────────────────────────────────────────────────

  Widget _buildInputPhase(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_add_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.joinOrganizationSubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Text(
          l10n.inviteCodeLabel,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _errorMsg != null
                  ? const Color(0xFFEF4444)
                  : AppColors.divider,
            ),
          ),
          child: TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              _UpperCaseFormatter(),
            ],
            maxLength: 8,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
            ),
            cursorColor: AppColors.purple,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: l10n.inviteCodeHint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
                letterSpacing: 0,
                fontWeight: FontWeight.w400,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              counterText: '',
            ),
            onSubmitted: (_) => _verify(),
          ),
        ),
        if (_errorMsg != null) ...[
          const SizedBox(height: 8),
          _ErrorBanner(message: _errorMsg!),
        ],
        const SizedBox(height: 28),
        _GradientButton(
          label: l10n.verifyCode,
          loading: _verifying,
          onTap: _verifying ? null : _verify,
        ),
      ],
    );
  }

  // ── Phase 2: confirmation ─────────────────────────────────────────────────────

  Widget _buildConfirmPhase(AppLocalizations l10n) {
    final resolved = _resolved!;
    final needsApproval = resolved.requiresApproval;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.45), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(
                        resolved.organizationName.isNotEmpty
                            ? resolved.organizationName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resolved.organizationName,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            resolved.defaultRole.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purpleLight,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    needsApproval
                        ? Icons.pending_rounded
                        : Icons.flash_on_rounded,
                    size: 16,
                    color: needsApproval
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF059669),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      needsApproval
                          ? l10n.requiresApprovalNote
                          : l10n.joinImmediateNote,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: needsApproval
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _joining ? null : _resetToInput,
            child: Text(
              l10n.changeInviteCode,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),
        ),
        if (_errorMsg != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(message: _errorMsg!),
        ],
        const SizedBox(height: 24),
        _GradientButton(
          label: l10n.confirmAndJoin,
          loading: _joining,
          onTap: _joining ? null : _join,
        ),
      ],
    );
  }

  // ── Phase 3: success ──────────────────────────────────────────────────────────

  Widget _buildSuccess(AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF059669).withValues(alpha: 0.45),
                  width: 2),
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF059669), size: 42),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          _joinedDirectly ? l10n.joinedOrgSuccess : l10n.requestSubmitted,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
        if (_resolved != null) ...[
          const SizedBox(height: 10),
          Text(
            _resolved!.organizationName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
        const SizedBox(height: 44),
        _GradientButton(
          label: l10n.btnOk,
          loading: false,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
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

  const _GradientButton({
    required this.label,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = onTap != null && !loading;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: active
              ? AppColors.brandGradient
              : const LinearGradient(
                  colors: [Color(0xFF2A2A45), Color(0xFF2A2A45)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
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
