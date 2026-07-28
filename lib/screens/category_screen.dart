import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/app_class.dart';
import '../models/app_event.dart';
import '../models/organization.dart';
import '../services/api_service.dart';
import '../services/saved_activities.dart';
import '../theme/app_theme.dart';
import 'activity_details_screen.dart';
import 'event_details_screen.dart';
import 'org_profile_screen.dart';
import '../routing/transitions.dart';
import 'see_all_events_screen.dart';
import 'see_all_orgs_screen.dart';
import 'see_all_screen.dart';

// ─── Shared gradient / icon pools (mirrors home_screen.dart) ─────────────────

const _gradients = [
  (Color(0xFF7C3AED), Color(0xFF3B82F6)),
  (Color(0xFF059669), Color(0xFF0EA5E9)),
  (Color(0xFFFF6B35), Color(0xFFEC4899)),
  (Color(0xFFEC4899), Color(0xFF7C3AED)),
];

const _icons = [
  Icons.self_improvement_rounded,
  Icons.sports_soccer_rounded,
  Icons.palette_rounded,
  Icons.music_note_rounded,
  Icons.precision_manufacturing_rounded,
  Icons.theater_comedy_rounded,
];

const _bannerStyles = [
  (Color(0xFFFF6B35), Color(0xFFEC4899), Icons.wb_sunny_rounded),
  (Color(0xFF7C3AED), Color(0xFF3B82F6), Icons.code_rounded),
  (Color(0xFF059669), Color(0xFF0EA5E9), Icons.weekend_rounded),
];

// ─── Local data classes ───────────────────────────────────────────────────────

class _Activity {
  final String id;
  final String name;
  final String studio;
  final String categoryId;
  final String category;
  final double rating;
  final int reviewCount;
  final Color colorStart;
  final Color colorEnd;
  final IconData icon;
  const _Activity({
    this.id = '',
    required this.name,
    required this.studio,
    required this.categoryId,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.colorStart,
    required this.colorEnd,
    required this.icon,
  });
}

class _Banner {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final Color colorStart;
  final Color colorEnd;
  final IconData icon;
  const _Banner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.colorStart,
    required this.colorEnd,
    required this.icon,
  });
}

List<_Activity> _toActivities(List<AppClass> src) =>
    src.asMap().entries.map((e) {
      final g = _gradients[e.key % _gradients.length];
      return _Activity(
        id: e.value.id,
        name: e.value.title,
        studio: e.value.organizationName,
        categoryId: e.value.categoryId,
        category: e.value.category,
        rating: e.value.averageRating,
        reviewCount: e.value.reviewCount,
        colorStart: g.$1,
        colorEnd: g.$2,
        icon: _icons[e.key % _icons.length],
      );
    }).toList();

List<_Banner> _toBanners(List<AppEvent> src) =>
    src.asMap().entries.map((e) {
      final s = _bannerStyles[e.key % _bannerStyles.length];
      return _Banner(
        id: e.value.id,
        title: e.value.title,
        subtitle: e.value.subtitle,
        badge: e.value.badge,
        colorStart: s.$1,
        colorEnd: s.$2,
        icon: s.$3,
      );
    }).toList();

// ─── Screen ───────────────────────────────────────────────────────────────────

class CategoryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final List<AppClass> classes;
  final List<AppEvent> events;
  final double? userLat;
  final double? userLng;
  final int? cityId;

  const CategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.classes,
    required this.events,
    this.userLat,
    this.userLng,
    this.cityId,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Organization> _orgs = [];
  bool _loadingOrgs = true;
  List<AppEvent> _events = [];
  bool _loadingEvents = true;
  List<AppClass> _classes = [];
  bool _loadingClasses = true;

  @override
  void initState() {
    super.initState();
    _loadOrgs();
    _loadEvents();
    _loadClasses();
  }

  Future<void> _loadOrgs() async {
    try {
      final orgs = await ApiService.getOrganizations(
        categoryId: int.tryParse(widget.categoryId),
        cityId: widget.cityId,
        userLat: widget.userLat,
        userLng: widget.userLng,
      );
      if (mounted) setState(() { _orgs = orgs; _loadingOrgs = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingOrgs = false);
    }
  }

  Future<void> _loadEvents() async {
    try {
      final events = await ApiService.getEvents(
        categoryId: int.tryParse(widget.categoryId),
        cityId: widget.cityId,
      );
      if (mounted) setState(() { _events = events; _loadingEvents = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await ApiService.getClasses(
        categoryId: int.tryParse(widget.categoryId),
        cityId: widget.cityId,
      );
      if (mounted) setState(() { _classes = classes; _loadingClasses = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingClasses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activities = _toActivities(_classes);
    final banners = _toBanners(_events);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: widget.categoryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.categoryIcon,
                        color: widget.categoryColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(widget.categoryName,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Scrollable sections ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Organizations ──────────────────────────────────
                    _SectionHeader(
                      title: l10n.tabOrganizations,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      onSeeAll: () => Navigator.of(context).push(
                          slideRoute(builder: (_) => SeeAllOrgsScreen(
                            categoryId: int.tryParse(widget.categoryId),
                            cityId: widget.cityId,
                          ))),
                    ),
                    const SizedBox(height: 16),
                    if (_loadingOrgs)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_orgs.isEmpty)
                      _buildEmpty(context,
                          icon: Icons.business_rounded,
                          title: l10n.noOrgsYet,
                          subtitle: l10n.checkBackSoonOrgs)
                    else
                      SizedBox(
                        height: 156,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _orgs.length,
                          itemBuilder: (ctx, i) => _OrgCard(org: _orgs[i]),
                        ),
                      ),
                    const SizedBox(height: 28),
                    // ── Events ─────────────────────────────────────────
                    _SectionHeader(
                      title: l10n.eventsSection,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      onSeeAll: () => Navigator.of(context).push(
                          slideRoute(builder: (_) => SeeAllEventsScreen(
                            categoryId: int.tryParse(widget.categoryId),
                            cityId: widget.cityId,
                          ))),
                    ),
                    const SizedBox(height: 16),
                    if (_loadingEvents)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (banners.isEmpty)
                      _buildEmpty(context,
                          icon: Icons.event_busy_rounded,
                          title: l10n.noActivitiesYet,
                          subtitle: l10n.checkBackSoonActivities)
                    else
                      SizedBox(
                        height: 168,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: banners.length,
                          itemBuilder: (ctx, i) => _BannerCard(banner: banners[i]),
                        ),
                      ),
                    const SizedBox(height: 28),
                    // ── Activities ─────────────────────────────────────
                    _SectionHeader(
                      title: l10n.activitiesSection,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      onSeeAll: () => Navigator.of(context).push(
                          slideRoute(builder: (_) => SeeAllScreen(
                              title: widget.categoryName,
                              initialCategory: widget.categoryName,
                              categoryId: int.tryParse(widget.categoryId),
                              cityId: widget.cityId))),
                    ),
                    const SizedBox(height: 16),
                    if (_loadingClasses)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (activities.isEmpty)
                      _buildEmpty(context,
                          icon: Icons.explore_off_rounded,
                          title: l10n.noActivitiesYet,
                          subtitle: l10n.checkBackSoonActivities)
                    else
                      SizedBox(
                        height: 248,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: activities.length,
                          itemBuilder: (ctx, i) => _ActivityCard(activity: activities[i]),
                        ),
                      ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section header (mirrors home_screen.dart) ────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsets padding;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    this.padding = EdgeInsets.zero,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll ?? () {},
            child: ShaderMask(
              shaderCallback: (b) => AppColors.brandGradient.createShader(b),
              child: Text(AppLocalizations.of(context)!.btnSeeAll,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Organization card (mirrors home_screen.dart _OrgCard) ───────────────────

class _OrgCard extends StatelessWidget {
  final Organization org;
  const _OrgCard({required this.org});

  static const _gradients = [
    (Color(0xFF7C3AED), Color(0xFFEC4899)),
    (Color(0xFF059669), Color(0xFF0EA5E9)),
    (Color(0xFFFF6B35), Color(0xFFEC4899)),
    (Color(0xFF3B82F6), Color(0xFF7C3AED)),
  ];

  @override
  Widget build(BuildContext context) {
    final g = _gradients[org.id.hashCode.abs() % _gradients.length];
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        slideRoute(builder: (_) => OrgProfileScreen(
          orgId: org.id,
          name: org.name,
          colorStart: g.$1,
          colorEnd: g.$2,
          category: org.category ?? '',
          rating: org.averageRating,
          reviewCount: org.reviewCount,
        )),
      ),
      child: Container(
        width: 192,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [g.$1, g.$2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: org.logoUrl != null && org.logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            org.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                org.name.isNotEmpty ? org.name[0].toUpperCase() : '?',
                                style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            org.name.isNotEmpty ? org.name[0].toUpperCase() : '?',
                            style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(org.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.25)),
                      if (org.city != null && org.city!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.location_on_rounded, size: 10, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Expanded(child: Text(org.city!, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted))),
                        ]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (org.description != null && org.description!.isNotEmpty)
              Expanded(
                child: Text(org.description!, maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textSecondary, height: 1.4)),
              )
            else
              const Spacer(),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFD700)),
              const SizedBox(width: 3),
              Text(org.averageRating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(width: 4),
              Text('(${org.reviewCount})',
                  style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Activity card (mirrors home_screen.dart _ActivityCard) ──────────────────

class _ActivityCard extends StatefulWidget {
  final _Activity activity;
  const _ActivityCard({required this.activity});
  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  bool _isSaved = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _isSaved = isSavedById(widget.activity.id);
    savedActivities.addListener(_onSavedChanged);
  }

  @override
  void dispose() {
    savedActivities.removeListener(_onSavedChanged);
    super.dispose();
  }

  void _onSavedChanged() {
    if (mounted) setState(() => _isSaved = isSavedById(widget.activity.id));
  }

  Future<void> _toggle() async {
    if (_toggling || widget.activity.id.isEmpty) return;
    setState(() { _toggling = true; _isSaved = !_isSaved; });
    final act = SavedActivity(
      classId: widget.activity.id,
      name: widget.activity.name,
      studio: widget.activity.studio,
      category: widget.activity.category,
      rating: widget.activity.rating,
      reviewCount: widget.activity.reviewCount,
      colorStart: widget.activity.colorStart,
      colorEnd: widget.activity.colorEnd,
      icon: widget.activity.icon,
    );
    try {
      if (_isSaved) {
        toggleSaved(act);
        final fav = await ApiService.addFavorite(widget.activity.id);
        favoriteIds[widget.activity.id] = fav.id;
      } else {
        toggleSaved(act);
        final favId = favoriteIds[widget.activity.id];
        if (favId != null) {
          await ApiService.removeFavorite(favId);
          favoriteIds.remove(widget.activity.id);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isSaved = !_isSaved);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ActivityDetailsScreen(
          classId: widget.activity.id.isNotEmpty ? widget.activity.id : null,
          name: widget.activity.name,
          studio: widget.activity.studio,
          category: widget.activity.category,
          rating: widget.activity.rating,
          reviewCount: widget.activity.reviewCount,
          colorStart: widget.activity.colorStart,
          colorEnd: widget.activity.colorEnd,
          heroIcon: widget.activity.icon,
        ),
      )),
      child: Container(
        width: 178,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.activity.colorStart, widget.activity.colorEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -16, bottom: -16,
                      child: Container(width: 72, height: 72,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1))),
                    ),
                    Center(
                      child: Icon(widget.activity.icon, size: 44,
                          color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(widget.activity.category,
                            style: GoogleFonts.poppins(fontSize: 9,
                                fontWeight: FontWeight.w600, color: Colors.white,
                                letterSpacing: 0.3)),
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: _toggle,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            color: _isSaved
                                ? const Color(0xFFFFD700)
                                : Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.activity.name,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary, height: 1.3)),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.storefront_rounded,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(widget.activity.studio,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textMuted)),
                    ),
                  ]),
                  const SizedBox(height: 9),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: Color(0xFFFFD700)),
                    const SizedBox(width: 3),
                    Text(widget.activity.rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(width: 4),
                    Text('(${widget.activity.reviewCount})',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textMuted)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Banner card (mirrors home_screen.dart _BannerCard) ──────────────────────

class _BannerCard extends StatelessWidget {
  final _Banner banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        slideRoute(builder: (_) => EventDetailsScreen(
          eventId: banner.id,
          colorStart: banner.colorStart,
          colorEnd: banner.colorEnd,
          icon: banner.icon,
        )),
      ),
      child: Container(
        width: screenW * 0.78,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [banner.colorStart, banner.colorEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: banner.colorStart.withValues(alpha: 0.4),
                blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24, top: -24,
              child: Container(width: 110, height: 110,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08))),
            ),
            Positioned(
              right: 24, bottom: -32,
              child: Container(width: 88, height: 88,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06))),
            ),
            Positioned(
              right: 20, top: 20,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: Icon(banner.icon, color: Colors.white, size: 32),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(banner.badge,
                        style: GoogleFonts.poppins(fontSize: 10,
                            fontWeight: FontWeight.w700, color: Colors.white,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(height: 8),
                  Text(banner.title,
                      style: GoogleFonts.poppins(fontSize: 20,
                          fontWeight: FontWeight.w700, color: Colors.white,
                          height: 1.2)),
                  const SizedBox(height: 4),
                  Text(banner.subtitle,
                      style: GoogleFonts.poppins(fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared empty state ───────────────────────────────────────────────────────

Widget _buildEmpty(BuildContext context,
    {required IconData icon, required String title, required String subtitle}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
    child: Center(
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
            child: Icon(icon, color: AppColors.textMuted, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textMuted)),
          ),
        ],
      ),
    ),
  );
}
