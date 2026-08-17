import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _currentController.addListener(_onFieldChanged);
    _newController.addListener(_onFieldChanged);
    _confirmController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (_submitted && mounted) setState(() {});
  }

  @override
  void dispose() {
    _currentController.removeListener(_onFieldChanged);
    _newController.removeListener(_onFieldChanged);
    _confirmController.removeListener(_onFieldChanged);
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _currentError(AppLocalizations l) {
    if (!_submitted) return null;
    if (_currentController.text.isEmpty) return l.fieldRequired;
    return null;
  }

  String? _newError(AppLocalizations l) {
    if (!_submitted) return null;
    if (_newController.text.isEmpty) return l.fieldRequired;
    if (_newController.text.length < 6) return l.errorPasswordTooShort;
    return null;
  }

  String? _confirmError(AppLocalizations l) {
    if (!_submitted) return null;
    if (_confirmController.text.isEmpty) return l.fieldRequired;
    if (_confirmController.text != _newController.text) {
      return l.errorPasswordsDoNotMatch;
    }
    return null;
  }

  Future<void> _submit(AppLocalizations l) async {
    if (_saving) return;
    setState(() => _submitted = true);
    if (_currentError(l) != null ||
        _newError(l) != null ||
        _confirmError(l) != null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.passwordChangedSuccess,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      final msg = l.errorCurrentPasswordWrong;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    _sectionLabel(l.accountSecuritySection),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _currentController,
                      hint: l.currentPasswordHint,
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      errorText: _currentError(l),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _newController,
                      hint: l.newPasswordHint,
                      prefixIcon: Icons.lock_rounded,
                      isPassword: true,
                      errorText: _newError(l),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _confirmController,
                      hint: l.confirmNewPasswordHint,
                      prefixIcon: Icons.lock_rounded,
                      isPassword: true,
                      errorText: _confirmError(l),
                    ),
                    const SizedBox(height: 32),
                    _buildSubmitButton(context, l),
                    const SizedBox(height: 32),
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

  Widget _buildHeader(BuildContext context, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
          const SizedBox(width: 14),
          Text(
            l.changePassword,
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, AppLocalizations l) {
    return GestureDetector(
      onTap: _saving ? null : () => _submit(l),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  l.changePassword,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
