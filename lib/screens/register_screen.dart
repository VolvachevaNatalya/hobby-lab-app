import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/social_login_button.dart';
import '../services/api_service.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (_submitted && mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() { _submitted = true; _errorMessage = null; });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ApiService.register(email: email, name: name, password: password);
      await ApiService.login(email, password, rememberMe: true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => const MainShell(),
          transitionsBuilder: (context, anim, secAnim, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToLogin() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Top row: back button + "Already have account?"
                Row(
                  children: [
                    _BackButton(),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${l10n.alreadyHaveAccount} ',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: _goToLogin,
                          child: ShaderMask(
                            shaderCallback: (b) =>
                                AppColors.brandGradient.createShader(b),
                            child: Text(
                              l10n.btnLogIn,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Text(
                  l10n.registerHeading,
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.registerFamiliesSubtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _nameController,
                  hint: l10n.fullNameHint,
                  prefixIcon: Icons.person_outline_rounded,
                  isRequired: true,
                  errorText: _submitted && name.isEmpty
                      ? l10n.fieldRequired
                      : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailController,
                  hint: l10n.emailHint,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  isRequired: true,
                  errorText: _submitted && email.isEmpty
                      ? l10n.fieldRequired
                      : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  hint: l10n.passwordHint,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  isRequired: true,
                  errorText: _submitted && password.isEmpty
                      ? l10n.fieldRequired
                      : null,
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
                    : GradientButton(label: l10n.btnContinue, onTap: _register),
                const SizedBox(height: 28),
                const _OrDivider(),
                const SizedBox(height: 20),
                SocialLoginButton(
                  icon: const BrandLetterIcon(
                      letter: 'G', color: Color(0xFF4285F4)),
                  label: l10n.continueWithGoogle,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                SocialLoginButton(
                  icon: const Icon(Icons.apple, color: Colors.white, size: 22),
                  label: l10n.continueWithApple,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                SocialLoginButton(
                  icon: const BrandLetterIcon(
                      letter: 'f',
                      color: Color(0xFF1877F2),
                      fontSize: 20),
                  label: l10n.continueWithFacebook,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                SocialLoginButton(
                  icon: const BrandLetterIcon(
                      letter: 'M', color: Color(0xFFEA4335)),
                  label: l10n.continueWithGmail,
                  onTap: () {},
                ),
                const SizedBox(height: 28),
                _TermsText(onLogin: _goToLogin),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Local helpers ────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 1),
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(context)!.orDivider,
            style: GoogleFonts.poppins(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
      ],
    );
  }
}

class _TermsText extends StatelessWidget {
  final VoidCallback onLogin;

  const _TermsText({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textMuted,
            height: 1.6,
          ),
          children: [
            TextSpan(text: l10n.byAgreeingTerms),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {},
                child: Text(
                  l10n.termsOfService,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.purpleLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            TextSpan(text: l10n.andConjunction),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {},
                child: Text(
                  l10n.privacyPolicy,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.purpleLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
