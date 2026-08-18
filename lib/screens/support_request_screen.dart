import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class SupportRequestScreen extends StatefulWidget {
  const SupportRequestScreen({super.key});

  @override
  State<SupportRequestScreen> createState() => _SupportRequestScreenState();
}

class _SupportRequestScreenState extends State<SupportRequestScreen> {
  // Stable English values sent to the backend.
  static const _subjectValues = [
    'App problem',
    'Question',
    'Organization / Event',
    'Account',
    'Suggestion',
    'Other',
  ];

  String _subject = _subjectValues.first;
  final _messageCtrl = TextEditingController();
  bool _submitting = false;
  bool _showMessageError = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  String _localizedSubject(String value, AppLocalizations l10n) {
    switch (value) {
      case 'App problem':
        return l10n.supportSubjectAppProblem;
      case 'Question':
        return l10n.supportSubjectQuestion;
      case 'Organization / Event':
        return l10n.supportSubjectOrgEvent;
      case 'Account':
        return l10n.supportSubjectAccount;
      case 'Suggestion':
        return l10n.supportSubjectSuggestion;
      case 'Other':
        return l10n.supportSubjectOther;
      default:
        return value;
    }
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final msg = _messageCtrl.text.trim();
    if (msg.isEmpty) {
      setState(() => _showMessageError = true);
      return;
    }
    setState(() {
      _submitting = true;
      _showMessageError = false;
    });
    try {
      await ApiService.submitSupportRequest(
        subject: _subject,
        message: msg,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.supportSuccessMessage,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.supportErrorMessage,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubjectDropdown(l10n),
                      const SizedBox(height: 20),
                      _buildMessageField(l10n),
                      const SizedBox(height: 28),
                      _buildSendButton(l10n),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
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
          Text(
            l10n.helpCenter,
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

  Widget _buildSubjectDropdown(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.supportSubjectLabel,
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
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _subject,
              isExpanded: true,
              dropdownColor: AppColors.surfaceElevated,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
              ),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              items: _subjectValues.map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    _localizedSubject(value, l10n),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value != null) setState(() => _subject = value);
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.supportMessageLabel,
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
              color: _showMessageError
                  ? const Color(0xFFEF4444)
                  : AppColors.divider,
            ),
          ),
          child: TextField(
            controller: _messageCtrl,
            maxLines: 6,
            minLines: 4,
            enabled: !_submitting,
            onChanged: (_) {
              if (_showMessageError && _messageCtrl.text.trim().isNotEmpty) {
                setState(() => _showMessageError = false);
              }
            },
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            cursorColor: AppColors.purple,
            decoration: InputDecoration(
              hintText: l10n.supportMessageHint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (_showMessageError) ...[
          const SizedBox(height: 6),
          Text(
            l10n.supportMessageRequired,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSendButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _submitting ? null : AppColors.brandGradient,
          color: _submitting ? AppColors.surfaceElevated : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _submitting
              ? null
              : [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: TextButton(
          onPressed: _submitting ? null : () => _submit(l10n),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.purple,
                  ),
                )
              : Text(
                  l10n.supportSendBtn,
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
