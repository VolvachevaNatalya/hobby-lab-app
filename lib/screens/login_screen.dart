import 'dart:io';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../routing/transitions.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';
import 'terms_privacy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ApiService.loginWithGoogle();
      if (!mounted) return;
      _navigateToMain();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('aborted')) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ApiService.loginWithApple();
      if (!mounted) return;
      _navigateToMain();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('aborted')) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ApiService.loginWithFacebook();
      if (!mounted) return;
      _navigateToMain();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('aborted')) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToMain() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      FcmService.initForAuthenticatedUser();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const MainShell(),
        transitionsBuilder: (context, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                _AppLogo(),
                const SizedBox(height: 28),
                Text(
                  l10n.loginTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginSubtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 2),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.redAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    children: [
                      _SocialButton(
                        icon: const FaIcon(FontAwesomeIcons.google,
                            color: Color(0xFF4285F4), size: 22),
                        label: l10n.continueWithGoogle,
                        onTap: _signInWithGoogle,
                      ),
                      if (Platform.isIOS) ...[
                        const SizedBox(height: 14),
                        _SocialButton(
                          icon: const FaIcon(FontAwesomeIcons.apple,
                              color: Colors.white, size: 22),
                          label: l10n.continueWithApple,
                          onTap: _signInWithApple,
                        ),
                      ],
                      const SizedBox(height: 14),
                      _SocialButton(
                        icon: const FaIcon(FontAwesomeIcons.facebook,
                            color: Color(0xFF1877F2), size: 22),
                        label: l10n.continueWithFacebook,
                        onTap: _signInWithFacebook,
                      ),
                      const SizedBox(height: 20),
                      _TermsText(l10n: l10n, context: context),
                    ],
                  ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Local helpers ────────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.science_rounded, color: Colors.white, size: 36),
    );
  }
}

class _TermsText extends StatefulWidget {
  final AppLocalizations l10n;
  final BuildContext context;

  const _TermsText({required this.l10n, required this.context});

  @override
  State<_TermsText> createState() => _TermsTextState();
}

class _TermsTextState extends State<_TermsText> {
  late final TapGestureRecognizer _termsRec;
  late final TapGestureRecognizer _privacyRec;

  @override
  void initState() {
    super.initState();
    _termsRec = TapGestureRecognizer()
      ..onTap = () => Navigator.of(widget.context).push(
            slideRoute(builder: (_) => const TermsPrivacyScreen()),
          );
    _privacyRec = TapGestureRecognizer()
      ..onTap = () => Navigator.of(widget.context).push(
            slideRoute(builder: (_) => const TermsPrivacyScreen()),
          );
  }

  @override
  void dispose() {
    _termsRec.dispose();
    _privacyRec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
        children: [
          TextSpan(text: '${l10n.byUsingAppYouAgree} '),
          TextSpan(
            text: l10n.termsOfService,
            style: const TextStyle(
              color: AppColors.purple,
              decoration: TextDecoration.underline,
            ),
            recognizer: _termsRec,
          ),
          TextSpan(text: ' ${l10n.andConjunction} '),
          TextSpan(
            text: l10n.privacyPolicy,
            style: const TextStyle(
              color: AppColors.purple,
              decoration: TextDecoration.underline,
            ),
            recognizer: _privacyRec,
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
