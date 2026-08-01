import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Shows a scope dialog for recurring event edits/deletes.
/// Returns 'single', 'future', 'series', or null (cancelled).
Future<String?> showEventScopeDialog(
  BuildContext context, {
  required String title,
  String? description,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _EventScopeDialog(title: title, description: description),
  );
}

class _EventScopeDialog extends StatelessWidget {
  final String title;
  final String? description;

  const _EventScopeDialog({required this.title, this.description});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description != null) ...[
            Text(
              description!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _ScopeOption(
            label: l10n.scopeOnlyThisEvent,
            icon: Icons.event_rounded,
            onTap: () => Navigator.of(context).pop('single'),
          ),
          const SizedBox(height: 8),
          _ScopeOption(
            label: l10n.scopeThisAndFollowing,
            icon: Icons.event_repeat_rounded,
            onTap: () => Navigator.of(context).pop('future'),
          ),
          const SizedBox(height: 8),
          _ScopeOption(
            label: l10n.scopeEntireSeries,
            icon: Icons.all_inclusive_rounded,
            onTap: () => Navigator.of(context).pop('series'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            l10n.btnCancel,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScopeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ScopeOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
