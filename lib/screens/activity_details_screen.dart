import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/saved_activities.dart';
import '../services/api_service.dart';
import '../models/app_class.dart';
import '../l10n/app_localizations.dart';
import 'chat_screen.dart';
import 'org_profile_screen.dart';
import 'reviews_screen.dart';



// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _stars(double rating, {double size = 16}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) {
      final icon = i < rating.floor()
          ? Icons.star_rounded
          : (rating - i >= 0.5)
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded;
      return Icon(icon, color: const Color(0xFFFFD700), size: size);
    }),
  );
}


String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}

// ─── Main screen ──────────────────────────────────────────────────────────────

class ActivityDetailsScreen extends StatefulWidget {
  final String? classId;
  final String name;
  final String studio;
  final String category;
  final double rating;
  final int reviewCount;
  final Color colorStart;
  final Color colorEnd;
  final IconData heroIcon;

  const ActivityDetailsScreen({
    super.key,
    this.classId,
    this.name = '',
    this.studio = '',
    this.category = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.colorStart = const Color(0xFF7C3AED),
    this.colorEnd = const Color(0xFFEC4899),
    this.heroIcon = Icons.category_rounded,
  });

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  late bool _isFavorite;
  AppClass? _details;
  String? _favoriteId;
  String? _orgAddress;
  String? _orgCity;
  String? _orgWebsite;
  int? _orgIdInt;
  late String _orgName;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _reviews = [];
  late double _rating;
  late int _reviewCount;

  @override
  void initState() {
    super.initState();
    _orgName = widget.studio;
    _rating = widget.rating;
    _reviewCount = widget.reviewCount;
    _isFavorite = widget.classId != null
        ? isSavedById(widget.classId!)
        : isSaved(widget.name);
    if (widget.classId != null) _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      // Load class + org data
      final body = await ApiService.getClassDetails(widget.classId!);
      if (!mounted) return;
      final classData = (body['class'] as Map<String, dynamic>?) ?? {};
      final orgData = (body['organization'] as Map<String, dynamic>?) ?? {};
      final orgId = (classData['organization_id'] as num?)?.toInt();

      // Load groups and reviews in parallel
      final groupsFuture = ApiService.getGroupsByClass(widget.classId!);
      final reviewsFuture = orgId != null
          ? ApiService.getReviews(orgId)
          : Future.value(<Map<String, dynamic>>[]);

      final groups = await groupsFuture;

      // Load all group schedules in parallel
      final schedulesPerGroup = await Future.wait(
        groups.map((g) async {
          try {
            return await ApiService.getGroupSchedules(g['id'].toString());
          } catch (_) {
            return <Map<String, dynamic>>[];
          }
        }),
      );
      final allSchedules = <Map<String, dynamic>>[];
      for (final sl in schedulesPerGroup) {
        allSchedules.addAll(sl);
      }

      List<Map<String, dynamic>> reviews = [];
      try {
        reviews = await reviewsFuture;
      } catch (_) {}

      double loadedRating = widget.rating;
      int loadedCount = widget.reviewCount;
      if (reviews.isNotEmpty) {
        loadedCount = reviews.length;
        final sum = reviews.fold<double>(
          0,
          (s, r) => s + ((r['rating'] ?? 0) as num).toDouble(),
        );
        loadedRating = sum / reviews.length;
      }

      if (!mounted) return;
      setState(() {
        _orgName = (orgData['name'] as String?) ?? widget.studio;
        _details = AppClass.fromJson({
          ...classData,
          'organization_name': orgData['name'],
          if (orgData['address'] != null) 'address': orgData['address'],
          if (orgData['website'] != null) 'website': orgData['website'],
        });
        _orgAddress = orgData['address']?.toString();
        _orgCity = orgData['city']?.toString();
        _orgWebsite = orgData['website']?.toString();
        _orgIdInt = orgId;
        _groups = groups;
        _schedules = allSchedules;
        _reviews = reviews;
        _rating = loadedRating;
        _reviewCount = loadedCount;
      });
    } catch (_) {}
  }

  Future<void> _openDirections() async {
    final addr = _orgAddress;
    if (addr == null || addr.isEmpty) return;
    final uri = Uri.parse(
        'https://maps.google.com/?q=${Uri.encodeComponent(addr)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _toggleFavorite() async {
    final l10n = AppLocalizations.of(context)!;
    final act = SavedActivity(
      classId: widget.classId ?? '',
      name: widget.name,
      studio: widget.studio,
      category: widget.category,
      rating: widget.rating,
      reviewCount: widget.reviewCount,
      colorStart: widget.colorStart,
      colorEnd: widget.colorEnd,
      icon: widget.heroIcon,
    );

    if (_isFavorite) {
      toggleSaved(act);
      setState(() => _isFavorite = false);
      if (_favoriteId != null) {
        try {
          await ApiService.removeFavorite(_favoriteId!);
          _favoriteId = null;
        } catch (_) {}
      }
    } else {
      toggleSaved(act);
      setState(() => _isFavorite = true);
      if (widget.classId != null) {
        try {
          final fav = await ApiService.addFavorite(widget.classId!);
          _favoriteId = fav.id;
        } catch (_) {}
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            _isFavorite ? l10n.savedToList : l10n.removedFromSaved,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable content ──
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroSection(
                  colorStart: widget.colorStart,
                  colorEnd: widget.colorEnd,
                  heroIcon: widget.heroIcon,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoSection(
                        name: widget.name,
                        studio: _orgName,
                        category: widget.category,
                        rating: _rating,
                        reviewCount: _reviewCount,
                        colorStart: widget.colorStart,
                        colorEnd: widget.colorEnd,
                        orgAddress: _orgAddress,
                        orgCity: _orgCity,
                        orgId: _orgIdInt?.toString(),
                      ),
                      const SizedBox(height: 20),
                      _ActionButtonsRow(
                        orgWebsite: _orgWebsite,
                        activityName: widget.name,
                        onDirections: _openDirections,
                      ),
                      const SizedBox(height: 28),
                      const _ScreenDivider(),
                      const SizedBox(height: 28),
                      _AboutSection(
                          description: _details?.description ?? ''),
                      const SizedBox(height: 28),
                      const _ScreenDivider(),
                      const SizedBox(height: 28),
                      _AgeSection(groups: _groups),
                      const SizedBox(height: 28),
                      const _ScreenDivider(),
                      const SizedBox(height: 28),
                      _GroupsSection(groups: _groups, schedules: _schedules),
                      const SizedBox(height: 28),
                      const _ScreenDivider(),
                      const SizedBox(height: 28),
                      _ScheduleSection(groups: _groups, schedules: _schedules),
                      const SizedBox(height: 28),
                      const _ScreenDivider(),
                      const SizedBox(height: 28),
                      _ReviewsSection(
                        rating: _rating,
                        reviewCount: _reviewCount,
                        reviews: _reviews,
                        onSeeAll: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            transitionDuration:
                                const Duration(milliseconds: 300),
                            pageBuilder: (_, _, _) => ReviewsScreen(
                              activityName: widget.name,
                              rating: _rating,
                              reviewCount: _reviewCount,
                              colorStart: widget.colorStart,
                              colorEnd: widget.colorEnd,
                              organizationId: _orgIdInt,
                            ),
                            transitionsBuilder: (_, animation, _, child) =>
                                SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOut)),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Fixed top bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    _HeaderBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    _HeaderBtn(
                      icon: Icons.share_rounded,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _HeaderBtn(
                      icon: _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      onTap: _toggleFavorite,
                      activeColor: _isFavorite ? AppColors.pink : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Sticky bottom bar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _ContactBar(
              orgId: _orgIdInt,
              orgName: _orgName,
              colorStart: widget.colorStart,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero image ───────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final Color colorStart;
  final Color colorEnd;
  final IconData heroIcon;

  const _HeroSection({
    required this.colorStart,
    required this.colorEnd,
    required this.heroIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorStart, colorEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 60,
              top: 60,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  heroIcon,
                  size: 54,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header button ────────────────────────────────────────────────────────────

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? activeColor;

  const _HeaderBtn({required this.icon, required this.onTap, this.activeColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: activeColor ?? Colors.white, size: 18),
      ),
    );
  }
}

// ─── Info section ─────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String name;
  final String studio;
  final String category;
  final double rating;
  final int reviewCount;
  final Color colorStart;
  final Color colorEnd;
  final String? orgAddress;
  final String? orgCity;
  final String? orgId;

  const _InfoSection({
    required this.name,
    required this.studio,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.colorStart,
    required this.colorEnd,
    this.orgAddress,
    this.orgCity,
    this.orgId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category + Open badges
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.3)),
              ),
              child: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purpleLight,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    AppLocalizations.of(context)!.openStatus,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Activity name
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        // Rating row
        Row(
          children: [
            _stars(rating, size: 18),
            const SizedBox(width: 8),
            Text(
              rating.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($reviewCount reviews)',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(height: 1, color: AppColors.divider),
        const SizedBox(height: 18),
        // Location
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded,
                  size: 16, color: AppColors.purple),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                () {
                  final loc = [orgAddress, orgCity]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(', ');
                  return loc.isNotEmpty
                      ? loc
                      : AppLocalizations.of(context)!.addressNotAvailable;
                }(),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(height: 1, color: AppColors.divider),
        const SizedBox(height: 18),
        // Organization card with avatar
        _OrgCard(
            studio: studio,
            category: category,
            colorStart: colorStart,
            colorEnd: colorEnd,
            orgId: orgId),
      ],
    );
  }
}

// ─── Organization card ────────────────────────────────────────────────────────

class _OrgCard extends StatelessWidget {
  final String studio;
  final String category;
  final Color colorStart;
  final Color colorEnd;
  final String? orgId;

  const _OrgCard({
    required this.studio,
    required this.category,
    required this.colorStart,
    required this.colorEnd,
    this.orgId,
  });

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, _, _) => OrgProfileScreen(
          orgId: orgId,
          name: studio,
          colorStart: colorStart,
          colorEnd: colorEnd,
          category: category,
        ),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
              parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openProfile(context),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colorStart, colorEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                _initials(studio),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studio,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.organizationLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _openProfile(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.3)),
              ),
              child: Text(
                AppLocalizations.of(context)!.btnView,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purpleLight,
                ),
              ),
            ),
          ),
        ],
      ),
    ),   // closes Container
    );   // closes GestureDetector
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _ActionButtonsRow extends StatelessWidget {
  final VoidCallback? onDirections;
  final String? orgWebsite;
  final String activityName;
  const _ActionButtonsRow({this.onDirections, this.orgWebsite, this.activityName = ''});

  @override
  Widget build(BuildContext context) {
    final hasWebsite = orgWebsite != null && orgWebsite!.isNotEmpty;
    return Row(
      children: [
        Expanded(
            child: _ActionBtn(
              icon: Icons.share_rounded,
              label: AppLocalizations.of(context)!.actionShare,
              onTap: () => Share.share(
                activityName.isNotEmpty
                    ? AppLocalizations.of(context)!.shareActivityMessage(activityName)
                    : AppLocalizations.of(context)!.shareActivityDefault,
              ),
            )),
        if (hasWebsite) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _ActionBtn(
              icon: Icons.language_rounded,
              label: AppLocalizations.of(context)!.actionWebsite,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.surfaceElevated,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  content: Text(
                    orgWebsite!,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: _ActionBtn(
            icon: Icons.directions_rounded,
            label: AppLocalizations.of(context)!.actionDirections,
            onTap: onDirections,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionBtn({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.purple, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section helpers ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ScreenDivider extends StatelessWidget {
  const _ScreenDivider();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: AppColors.divider);
}

// ─── About section ────────────────────────────────────────────────────────────

class _AboutSection extends StatefulWidget {
  final String description;
  const _AboutSection({required this.description});

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.description.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(l10n.aboutSection),
          const SizedBox(height: 12),
          Text(
            l10n.noDescriptionAvailable,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.65,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.aboutSection),
        const SizedBox(height: 12),
        Text(
          widget.description,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: ShaderMask(
            shaderCallback: (b) => AppColors.brandGradient.createShader(b),
            child: Text(
              _expanded ? l10n.showLess : l10n.showMore,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Age section ──────────────────────────────────────────────────────────────

class _AgeSection extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  const _AgeSection({required this.groups});

  String get _ageRange {
    if (groups.isEmpty) return 'Any age';
    int? minAge, maxAge;
    for (final g in groups) {
      final from = g['age_from'] as int?;
      final to = g['age_to'] as int?;
      if (from != null) minAge = (minAge == null) ? from : (from < minAge ? from : minAge);
      if (to != null) maxAge = (maxAge == null) ? to : (to > maxAge ? to : maxAge);
    }
    if (minAge != null && maxAge != null) return '$minAge – $maxAge years';
    if (minAge != null) return '$minAge+ years';
    return 'Any age';
  }

  String get _capacity {
    if (groups.isEmpty) return '—';
    int total = 0;
    for (final g in groups) {
      total += (g['capacity'] as int?) ?? 0;
    }
    return total > 0 ? 'Up to $total' : '—';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(AppLocalizations.of(context)!.ageInfoSection),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.child_care_rounded,
                iconColor: AppColors.purple,
                iconBg: AppColors.purple.withValues(alpha: 0.12),
                label: AppLocalizations.of(context)!.ageRange,
                value: _ageRange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.group_rounded,
                iconColor: const Color(0xFF0EA5E9),
                iconBg: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                label: AppLocalizations.of(context)!.groupSize,
                value: _capacity,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Groups section ───────────────────────────────────────────────────────────

class _GroupsSection extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> schedules;
  const _GroupsSection({required this.groups, required this.schedules});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(AppLocalizations.of(context)!.groupsSection),
        const SizedBox(height: 14),
        if (groups.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(AppLocalizations.of(context)!.noGroupsAvailable,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted)),
          )
        else
          ...groups.map((g) {
            final groupSchedules = schedules
                .where((s) => s['group_id'].toString() == g['id'].toString())
                .toList();
            return _GroupTile(group: g, schedules: groupSchedules);
          }),
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> schedules;
  const _GroupTile({required this.group, required this.schedules});

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  String _fmtTime(String? t) {
    if (t == null || t.isEmpty) return '';
    final p = t.split(':');
    return p.length >= 2 ? '${p[0]}:${p[1]}' : t;
  }

  @override
  Widget build(BuildContext context) {
    final name = group['name']?.toString() ?? 'Group';
    final ageFrom = group['age_from'] as int?;
    final ageTo = group['age_to'] as int?;
    final capacity = group['capacity'] as int?;

    String ageLabel = '';
    if (ageFrom != null && ageTo != null) {
      ageLabel = '$ageFrom–$ageTo yrs';
    } else if (ageFrom != null) {
      ageLabel = '$ageFrom+ yrs';
    }

    // Build schedule summary: "Mon 10:00–11:00, Wed 14:00–15:00"
    final schedSummary = schedules.map((s) {
      final day = (s['day_of_week'] as int?)?.clamp(0, 6) ?? 0;
      final start = _fmtTime(s['start_time']?.toString());
      final end = _fmtTime(s['end_time']?.toString());
      return '${_days[day]} $start–$end';
    }).join('  ·  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.group_rounded, color: AppColors.purple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                if (ageLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(ageLabel,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
                ],
                if (schedSummary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(schedSummary,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.purpleLight, fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
          if (capacity != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('≤$capacity',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0EA5E9))),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Schedule section ─────────────────────────────────────────────────────────

class _ScheduleSection extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> schedules;
  const _ScheduleSection({required this.groups, required this.schedules});

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  String _fmt(String? t) {
    if (t == null || t.isEmpty) return '';
    final parts = t.split(':');
    if (parts.length < 2) return t;
    return '${parts[0]}:${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(AppLocalizations.of(context)!.scheduleSection),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(AppLocalizations.of(context)!.noScheduleAvailable,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted)),
          ),
        ],
      );
    }

    // Group schedules by group name
    final groupMap = {for (final g in groups) g['id'].toString(): g['name']?.toString() ?? 'Group'};

    // Group by day
    final byDay = <int, List<Map<String, dynamic>>>{};
    for (final s in schedules) {
      final day = s['day_of_week'] as int? ?? 0;
      byDay.putIfAbsent(day, () => []).add(s);
    }
    final sortedDays = byDay.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(AppLocalizations.of(context)!.scheduleSection),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: sortedDays.map((day) {
              final daySlots = byDay[day]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        _days[day.clamp(0, 6)],
                        style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8, runSpacing: 6,
                        children: daySlots.map((s) {
                          final start = _fmt(s['start_time']?.toString());
                          final end = _fmt(s['end_time']?.toString());
                          final gName = groupMap[s['group_id'].toString()];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              gName != null ? '$start – $end ($gName)' : '$start – $end',
                              style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w500,
                                color: AppColors.purpleLight,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Reviews section ──────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final List<Map<String, dynamic>> reviews;
  final VoidCallback? onSeeAll;

  const _ReviewsSection({
    required this.rating,
    required this.reviewCount,
    this.reviews = const [],
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preview = reviews.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionTitle(l10n.reviewsSection),
            const Spacer(),
            GestureDetector(
              onTap: onSeeAll,
              child: ShaderMask(
                shaderCallback: (b) =>
                    AppColors.brandGradient.createShader(b),
                child: Text(
                  l10n.btnSeeAll,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Rating summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                child: Text(
                  rating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _stars(rating, size: 16),
              const SizedBox(height: 4),
              Text(
                '$reviewCount ${l10n.reviewsLabel}',
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (reviewCount == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.noReviewsYet,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
            ),
          )
        else
          ...preview.map((r) => _ReviewPreviewCard(review: r)),
      ],
    );
  }
}

// ─── Review preview card ──────────────────────────────────────────────────────

class _ReviewPreviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewPreviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] ?? 0) as num;
    final comment = (review['comment'] ?? '').toString();
    final reviewerName = (review['reviewer_name'] ??
            review['user_name'] ??
            'Anonymous')
        .toString();
    final createdAt = review['created_at']?.toString() ?? '';
    final dateStr = _fmtDate(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              _stars(rating.toDouble(), size: 14),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ─── Contact bar ─────────────────────────────────────────────────────────────

class _ContactBar extends StatefulWidget {
  final int? orgId;
  final String orgName;
  final Color colorStart;

  const _ContactBar({
    this.orgId,
    required this.orgName,
    required this.colorStart,
  });

  @override
  State<_ContactBar> createState() => _ContactBarState();
}

class _ContactBarState extends State<_ContactBar> {
  bool _loading = false;

  String get _initials {
    final words = widget.orgName.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return widget.orgName.substring(0, widget.orgName.length.clamp(0, 2)).toUpperCase();
  }

  Future<void> _contact() async {
    if (_loading) return;
    setState(() => _loading = true);
    String? conversationId;
    try {
      if (widget.orgId != null) {
        final convo = await ApiService.createConversation(widget.orgId!);
        conversationId = convo['id']?.toString();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => ChatScreen(
        conversationId: conversationId,
        name: widget.orgName.isNotEmpty ? widget.orgName : 'Organization',
        initials: _initials.isNotEmpty ? _initials : '?',
        avatarColor: widget.colorStart,
      ),
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: GestureDetector(
            onTap: _contact,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n.btnContact,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
