import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../locale_provider.dart';
import 'edit_profile_screen.dart';
import 'language_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = true;
  bool _classReminders = true;
  bool _promotions = false;
  bool _newActivities = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(l10n.sectionAccount),
                    const SizedBox(height: 10),
                    _buildCard([
                      _NavRow(
                        icon: Icons.person_outline_rounded,
                        iconColor: AppColors.purple,
                        label: l10n.editProfile,
                        onTap: () => _push(context, const EditProfileScreen()),
                      ),
                      _NavRow(
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFF0EA5E9),
                        label: l10n.changePassword,
                        onTap: () {},
                      ),
                    ]),
                    const SizedBox(height: 28),
                    _sectionLabel(l10n.sectionNotifications),
                    const SizedBox(height: 10),
                    _buildCard([
                      _ToggleRow(
                        icon: Icons.notifications_rounded,
                        iconColor: AppColors.purple,
                        label: l10n.pushNotifications,
                        value: _pushEnabled,
                        onChanged: (v) => setState(() => _pushEnabled = v),
                      ),
                      _ToggleRow(
                        icon: Icons.calendar_today_rounded,
                        iconColor: const Color(0xFF0EA5E9),
                        label: l10n.classReminders,
                        value: _classReminders,
                        onChanged: (v) => setState(() => _classReminders = v),
                      ),
                      _ToggleRow(
                        icon: Icons.local_offer_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        label: l10n.promotionsOffers,
                        value: _promotions,
                        onChanged: (v) => setState(() => _promotions = v),
                      ),
                      _ToggleRow(
                        icon: Icons.explore_rounded,
                        iconColor: const Color(0xFFEC4899),
                        label: l10n.newActivitiesNearby,
                        value: _newActivities,
                        onChanged: (v) => setState(() => _newActivities = v),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    _sectionLabel(l10n.sectionApp),
                    const SizedBox(height: 10),
                    _buildCard([
                      _NavRow(
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF059669),
                        label: l10n.language,
                        trailing: ValueListenableBuilder<Locale>(
                          valueListenable: localeNotifier,
                          builder: (_, locale, __) => Text(
                            switch (locale.languageCode) {
                              'ru' => 'Русский',
                              'he' => 'עברית',
                              _ => 'English',
                            },
                            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ),
                        onTap: () => _push(context, const LanguageSelectionScreen()),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    _sectionLabel(l10n.sectionSupport),
                    const SizedBox(height: 10),
                    _buildCard([
                      _NavRow(
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF0EA5E9),
                        label: l10n.helpCenter,
                        onTap: () {},
                      ),
                      _NavRow(
                        icon: Icons.mail_outline_rounded,
                        iconColor: AppColors.purple,
                        label: l10n.contactUs,
                        onTap: () {},
                      ),
                    ]),
                    const SizedBox(height: 32),
                    _sectionLabel(l10n.sectionDangerZone),
                    const SizedBox(height: 10),
                    _buildDangerCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            l10n.settingsTitle,
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

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 1.0,
          ),
        ),
      );

  Widget _buildCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          return Column(
            children: [
              rows[i],
              if (i < rows.length - 1)
                const Divider(
                  height: 1,
                  color: AppColors.divider,
                  indent: 56,
                  endIndent: 16,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDangerCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showDeleteDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.deleteAccount,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.deleteAccountDesc,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Color(0xFFEF4444)),
            ],
          ),
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ));
  }

  void _showDeleteDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.deleteAccount,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          l10n.deleteAccountConfirm,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.btnCancel,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.btnDelete,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
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
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 6),
            ],
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.purple,
            activeTrackColor: AppColors.purple.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.divider,
          ),
        ],
      ),
    );
  }
}
