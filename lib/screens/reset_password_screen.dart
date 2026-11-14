import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_button.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onFieldChanged);
    _newPasswordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (_submitted && mounted) setState(() {});
  }

  @override
  void dispose() {
    _otpController.removeListener(_onFieldChanged);
    _newPasswordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _otpError(AppLocalizations l10n) {
    if (!_submitted) return null;
    final v = _otpController.text.trim();
    if (v.isEmpty) return l10n.errorCodeRequired;
    if (v.length != 6) return l10n.errorInvalidResetCode;
    return null;
  }

  String? _passwordError(AppLocalizations l10n) {
    if (!_submitted) return null;
    if (_newPasswordController.text.isEmpty) return l10n.fieldRequired;
    if (_newPasswordController.text.length < 6) return l10n.errorPasswordTooShort;
    return null;
  }

  String? _confirmError(AppLocalizations l10n) {
    if (!_submitted) return null;
    if (_confirmPasswordController.text.isEmpty) return l10n.fieldRequired;
    if (_confirmPasswordController.text != _newPasswordController.text) {
      return l10n.errorPasswordsDoNotMatch;
    }
    return null;
  }

  bool _hasValidationError(AppLocalizations l10n) =>
      _otpError(l10n) != null ||
      _passwordError(l10n) != null ||
      _confirmError(l10n) != null;

  Future<void> _submit() async {
    setState(() { _submitted = true; _errorMessage = null; });
    final l10n = AppLocalizations.of(context)!;
    if (_hasValidationError(l10n)) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.resetPassword(
        email: widget.email,
        otp: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      if (mounted) {
        setState(() =>
            _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (b) => AppColors.brandGradient.createShader(b),
              child: const Icon(Icons.check_circle_rounded,
                  size: 56, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.resetPasswordSuccessMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Pop back to Login, clearing the forgot-password stack.
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: ShaderMask(
              shaderCallback: (b) => AppColors.brandGradient.createShader(b),
              child: Text(
                l10n.btnLogIn,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _BackButton(),
                  const SizedBox(height: 36),
                  Text(
                    l10n.resetPasswordTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.resetPasswordOtpLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _otpController,
                    hint: l10n.resetPasswordOtpHint,
                    prefixIcon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    errorText: _otpError(l10n),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _newPasswordController,
                    hint: l10n.newPasswordHint,
                    prefixIcon: Icons.lock_rounded,
                    isPassword: true,
                    errorText: _passwordError(l10n),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _confirmPasswordController,
                    hint: l10n.confirmNewPasswordHint,
                    prefixIcon: Icons.lock_rounded,
                    isPassword: true,
                    errorText: _confirmError(l10n),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GradientButton(
                          label: l10n.resetPasswordSubmitBtn,
                          onTap: _submit,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 18,
        ),
      ),
    );
  }
}
