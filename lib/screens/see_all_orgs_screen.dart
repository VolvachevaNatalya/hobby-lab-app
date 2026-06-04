import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/organization.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'org_profile_screen.dart';

class SeeAllOrgsScreen extends StatefulWidget {
  final String? city;
  const SeeAllOrgsScreen({super.key, this.city});

  @override
  State<SeeAllOrgsScreen> createState() => _SeeAllOrgsScreenState();
}

class _SeeAllOrgsScreenState extends State<SeeAllOrgsScreen> {
  List<Organization> _orgs = [];
  bool _loading = true;
  String _query = '';
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final orgs = await ApiService.getOrganizations(city: widget.city);
      if (mounted) setState(() { _orgs = orgs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Organization> get _filtered {
    if (_query.isEmpty) return _orgs;
    final q = _query.toLowerCase();
    return _orgs.where((o) =>
        o.name.toLowerCase().contains(q) ||
        (o.city?.toLowerCase().contains(q) ?? false) ||
        (o.description?.toLowerCase().contains(q) ?? false)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 42, height: 42,
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
                  Expanded(
                    child: Text(l10n.organizationsNearYou,
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  Text(
                    _loading ? '' : l10n.countResults(items.length),
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: _ctrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13),
                  cursorColor: AppColors.purple,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchActivitiesHint,
                    hintStyle: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                            onTap: () => setState(() { _query = ''; _ctrl.clear(); }),
                            child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: const Icon(Icons.business_rounded, color: AppColors.textMuted, size: 32),
                              ),
                              const SizedBox(height: 16),
                              Text(l10n.noOrgsYet,
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              Text(l10n.checkBackSoonOrgs,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: items.length,
                          itemBuilder: (ctx, i) => _OrgGridCard(org: items[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrgGridCard extends StatelessWidget {
  final Organization org;
  const _OrgGridCard({required this.org});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => OrgProfileScreen(
          orgId: org.id,
          name: org.name,
          colorStart: const Color(0xFF7C3AED),
          colorEnd: const Color(0xFFEC4899),
          category: org.category ?? '',
          rating: org.averageRating,
          reviewCount: org.reviewCount,
        ),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  org.name.isNotEmpty ? org.name[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(org.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3)),
            if (org.city != null && org.city!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 11, color: AppColors.textMuted),
                const SizedBox(width: 2),
                Expanded(child: Text(org.city!, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted))),
              ]),
            ],
            const Spacer(),
            Row(children: [
              const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFD700)),
              const SizedBox(width: 3),
              Text(org.averageRating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ]),
          ],
        ),
      ),
    );
  }
}
