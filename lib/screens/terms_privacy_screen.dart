import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../routing/transitions.dart';
import 'legal_document_screen.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildCard(context, l10n),
            ),
          ],
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
            l10n.termsPrivacy,
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

  Widget _buildCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _DocRow(
            icon: Icons.description_outlined,
            iconColor: AppColors.purple,
            label: l10n.touTitle,
            onTap: () => Navigator.of(context).push(
              slideRoute(
                builder: (_) => LegalDocumentScreen(
                  title: l10n.touTitle,
                  lastUpdated: l10n.touLastUpdated,
                  sections: _touSections(l10n),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.divider, indent: 56),
          _DocRow(
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF0EA5E9),
            label: l10n.ppTitle,
            onTap: () => Navigator.of(context).push(
              slideRoute(
                builder: (_) => LegalDocumentScreen(
                  title: l10n.ppTitle,
                  lastUpdated: l10n.ppLastUpdated,
                  sections: _ppSections(l10n),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LegalSection> _touSections(AppLocalizations l10n) => [
        LegalSection(title: l10n.touS1Title, body: l10n.touS1Body),
        LegalSection(title: l10n.touS2Title, body: l10n.touS2Body),
        LegalSection(title: l10n.touS3Title, body: l10n.touS3Body),
        LegalSection(title: l10n.touS4Title, body: l10n.touS4Body),
        LegalSection(title: l10n.touS5Title, body: l10n.touS5Body),
        LegalSection(title: l10n.touS6Title, body: l10n.touS6Body),
        LegalSection(title: l10n.touS7Title, body: l10n.touS7Body),
        LegalSection(title: l10n.touS8Title, body: l10n.touS8Body),
        LegalSection(title: l10n.touS9Title, body: l10n.touS9Body),
        LegalSection(title: l10n.touS10Title, body: l10n.touS10Body),
        LegalSection(title: l10n.touS11Title, body: l10n.touS11Body),
        LegalSection(title: l10n.touS12Title, body: l10n.touS12Body),
        LegalSection(title: l10n.touS13Title, body: l10n.touS13Body),
        LegalSection(title: l10n.touS14Title, body: l10n.touS14Body),
      ];

  List<LegalSection> _ppSections(AppLocalizations l10n) => [
        LegalSection(title: l10n.ppS1Title, body: l10n.ppS1Body),
        LegalSection(title: l10n.ppS2Title, body: l10n.ppS2Body),
        LegalSection(title: l10n.ppS3Title, body: l10n.ppS3Body),
        LegalSection(title: l10n.ppS4Title, body: l10n.ppS4Body),
        LegalSection(title: l10n.ppS5Title, body: l10n.ppS5Body),
        LegalSection(title: l10n.ppS6Title, body: l10n.ppS6Body),
        LegalSection(title: l10n.ppS7Title, body: l10n.ppS7Body),
        LegalSection(title: l10n.ppS8Title, body: l10n.ppS8Body),
        LegalSection(title: l10n.ppS9Title, body: l10n.ppS9Body),
        LegalSection(title: l10n.ppS10Title, body: l10n.ppS10Body),
        LegalSection(title: l10n.ppS11Title, body: l10n.ppS11Body),
        LegalSection(title: l10n.ppS12Title, body: l10n.ppS12Body),
        LegalSection(title: l10n.ppS13Title, body: l10n.ppS13Body),
        LegalSection(title: l10n.ppS14Title, body: l10n.ppS14Body),
        LegalSection(title: l10n.ppS15Title, body: l10n.ppS15Body),
        LegalSection(title: l10n.ppS16Title, body: l10n.ppS16Body),
      ];
}

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
