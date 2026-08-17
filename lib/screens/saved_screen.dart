import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/organization.dart';
import '../models/app_event.dart';
import '../services/saved_activities.dart';
import '../services/api_service.dart';
import 'activity_details_screen.dart';
import 'org_profile_screen.dart';
import 'event_details_screen.dart';
import '../routing/transitions.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await ApiService.getFavorites();

      // Partition by entity_type
      final classFavs = favs.where((f) => f.entityType == 'class' || f.entityType == '').toList();
      final orgFavs = favs.where((f) => f.entityType == 'organization').toList();
      final eventFavs = favs.where((f) => f.entityType == 'event').toList();

      // Clear all caches
      favoriteIds.clear();
      orgFavoriteIds.clear();
      eventFavoriteIds.clear();

      // Classes
      for (final f in classFavs) {
        favoriteIds[f.entityId] = f.id;
      }
      final classSavedIds = classFavs.map((f) => f.entityId).toSet();
      final classes = await ApiService.getClasses();
      if (!mounted) return;
      final matched = classes.where((c) => classSavedIds.contains(c.id)).toList();
      savedActivities.value = matched.asMap().entries.map((e) {
        return SavedActivity(
          classId: e.value.id,
          name: e.value.title,
          studio: e.value.organizationName,
          category: e.value.category,
          primaryCategory: e.value.primaryCategory,
          rating: e.value.averageRating,
          reviewCount: e.value.reviewCount,
          colorStart: _colorForIndex(e.key),
          colorEnd: _colorEndForIndex(e.key),
          icon: _iconForCategory(e.value.category),
        );
      }).toList();

      // Organizations
      for (final f in orgFavs) {
        orgFavoriteIds[f.entityId] = f.id;
      }
      savedOrgIds.value = orgFavs.map((f) => f.entityId).toSet();
      if (orgFavs.isNotEmpty) {
        final orgResults = await Future.wait(
          orgFavs.map((f) => ApiService.getOrganization(f.entityId)
              .catchError((_) => <String, dynamic>{})),
        );
        if (!mounted) return;
        final orgs = orgResults
            .map((r) => r.isNotEmpty ? Organization.fromJson(r) : null)
            .whereType<Organization>()
            .toList();
        savedOrgsList.value = orgs;
      } else {
        savedOrgsList.value = [];
      }

      // Events
      for (final f in eventFavs) {
        eventFavoriteIds[f.entityId] = f.id;
      }
      savedEventIds.value = eventFavs.map((f) => f.entityId).toSet();
      if (eventFavs.isNotEmpty) {
        final eventResults = await Future.wait(
          eventFavs.map((f) =>
              ApiService.getEvent(f.entityId).catchError((_) => null as dynamic)),
        );
        if (!mounted) return;
        savedEventsList.value =
            eventResults.whereType<AppEvent>().toList();
      } else {
        savedEventsList.value = [];
      }
    } catch (_) {
      // keep existing local state on error
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unsaveClass(SavedActivity activity) async {
    final favId = favoriteIds[activity.classId];
    toggleSaved(activity);
    if (favId != null) {
      try {
        await ApiService.removeFavorite(favId);
        favoriteIds.remove(activity.classId);
      } catch (_) {}
    }
  }

  Future<void> _unsaveOrg(String orgId) async {
    final favId = orgFavoriteIds[orgId];
    removeSavedOrg(orgId);
    if (favId != null) {
      try {
        await ApiService.removeFavorite(favId);
      } catch (_) {}
    }
  }

  Future<void> _unsaveEvent(String eventId) async {
    final favId = eventFavoriteIds[eventId];
    removeSavedEvent(eventId);
    if (favId != null) {
      try {
        await ApiService.removeFavorite(favId);
      } catch (_) {}
    }
  }

  static Color _colorForIndex(int i) {
    const starts = [
      Color(0xFF7C3AED),
      Color(0xFF059669),
      Color(0xFFFF6B35),
      Color(0xFFEC4899),
      Color(0xFF0EA5E9),
    ];
    return starts[i % starts.length];
  }

  static Color _colorEndForIndex(int i) {
    const ends = [
      Color(0xFF3B82F6),
      Color(0xFF0EA5E9),
      Color(0xFFEC4899),
      Color(0xFF7C3AED),
      Color(0xFF059669),
    ];
    return ends[i % ends.length];
  }

  static IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'sport':
        return Icons.sports_soccer_rounded;
      case 'art':
        return Icons.palette_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'theater':
        return Icons.theater_comedy_rounded;
      case 'education':
        return Icons.menu_book_rounded;
      default:
        return Icons.self_improvement_rounded;
    }
  }

  static const _orgGradients = [
    (Color(0xFF7C3AED), Color(0xFFEC4899)),
    (Color(0xFF059669), Color(0xFF0EA5E9)),
    (Color(0xFFFF6B35), Color(0xFFEC4899)),
    (Color(0xFF3B82F6), Color(0xFF7C3AED)),
  ];

  static const _eventGradients = [
    (Color(0xFFEC4899), Color(0xFF7C3AED)),
    (Color(0xFF0EA5E9), Color(0xFF059669)),
    (Color(0xFFFF6B35), Color(0xFFEC4899)),
    (Color(0xFF7C3AED), Color(0xFF3B82F6)),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ValueListenableBuilder<List<Organization>>(
                valueListenable: savedOrgsList,
                builder: (ctx, orgs, _) =>
                    ValueListenableBuilder<List<AppEvent>>(
                  valueListenable: savedEventsList,
                  builder: (ctx, events, _) =>
                      ValueListenableBuilder<List<SavedActivity>>(
                    valueListenable: savedActivities,
                    builder: (ctx, classes, _) {
                      final isEmpty =
                          orgs.isEmpty && classes.isEmpty && events.isEmpty;
                      return isEmpty
                          ? Column(children: [_buildHeader(l10n), const Divider(height: 1, color: AppColors.divider), Expanded(child: _buildEmpty(l10n))])
                          : _buildContent(context, l10n, orgs, classes, events);
                    },
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Text(
        l10n.saved,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    List<Organization> orgs,
    List<SavedActivity> classes,
    List<AppEvent> events,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildHeader(l10n),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // ── Saved Organizations ──────────────────────────────────────────
        if (orgs.isNotEmpty) ...[
          SliverToBoxAdapter(child: _sectionLabel(l10n.savedOrganizations)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final org = orgs[i];
                final g = _orgGradients[org.id.hashCode.abs() % _orgGradients.length];
                return _SavedOrgCard(
                  org: org,
                  colorStart: g.$1,
                  colorEnd: g.$2,
                  onUnsave: () => _unsaveOrg(org.id),
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
                );
              },
              childCount: orgs.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],

        // ── Saved Classes ────────────────────────────────────────────────
        if (classes.isNotEmpty) ...[
          SliverToBoxAdapter(child: _sectionLabel(l10n.savedClasses)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 178 / 252,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _SavedClassCard(
                  activity: classes[i],
                  onUnsave: () => _unsaveClass(classes[i]),
                ),
                childCount: classes.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],

        // ── Saved Events ─────────────────────────────────────────────────
        if (events.isNotEmpty) ...[
          SliverToBoxAdapter(child: _sectionLabel(l10n.savedEvents)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final event = events[i];
                final g = _eventGradients[i % _eventGradients.length];
                return _SavedEventCard(
                  event: event,
                  colorStart: g.$1,
                  colorEnd: g.$2,
                  onUnsave: () => _unsaveEvent(event.id),
                  onTap: () => Navigator.of(context).push(
                    slideRoute(builder: (_) => EventDetailsScreen(
                      eventId: event.id,
                      colorStart: g.$1,
                      colorEnd: g.$2,
                    )),
                  ),
                );
              },
              childCount: events.length,
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.textMuted,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noSavedActivities,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              l10n.noSavedSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Saved Org Card ───────────────────────────────────────────────────────────

class _SavedOrgCard extends StatelessWidget {
  final Organization org;
  final Color colorStart;
  final Color colorEnd;
  final VoidCallback onUnsave;
  final VoidCallback onTap;

  const _SavedOrgCard({
    required this.org,
    required this.colorStart,
    required this.colorEnd,
    required this.onUnsave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = org.name.isNotEmpty ? org.name[0].toUpperCase() : '?';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorStart, colorEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: org.logoUrl != null && org.logoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.network(
                        org.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
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
                    org.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (org.city != null && org.city!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            org.city!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Color(0xFFFFD700)),
                      const SizedBox(width: 3),
                      Text(
                        org.averageRating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${org.reviewCount})',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onUnsave,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFEC4899),
                  size: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Saved Class Card (unchanged from original) ───────────────────────────────

class _SavedClassCard extends StatelessWidget {
  final SavedActivity activity;
  final VoidCallback onUnsave;

  const _SavedClassCard({required this.activity, required this.onUnsave});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ActivityDetailsScreen(
          classId: activity.classId.isNotEmpty ? activity.classId : null,
          name: activity.name,
          studio: activity.studio,
          category: activity.category,
          rating: activity.rating,
          reviewCount: activity.reviewCount,
          colorStart: activity.colorStart,
          colorEnd: activity.colorEnd,
          heroIcon: activity.icon,
        ),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [activity.colorStart, activity.colorEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        right: -16,
                        bottom: -16,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          activity.icon,
                          size: 44,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activity.primaryCategory?.localizedName(locale) ?? activity.category,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: onUnsave,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899).withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            activity.studio,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFFFD700),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          activity.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '(${activity.reviewCount})',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
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

// ─── Saved Event Card ─────────────────────────────────────────────────────────

class _SavedEventCard extends StatelessWidget {
  final AppEvent event;
  final Color colorStart;
  final Color colorEnd;
  final VoidCallback onUnsave;
  final VoidCallback onTap;

  const _SavedEventCard({
    required this.event,
    required this.colorStart,
    required this.colorEnd,
    required this.onUnsave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final months = [
      '',
      l10n.monthJanAbbrev, l10n.monthFebAbbrev, l10n.monthMarAbbrev,
      l10n.monthAprAbbrev, l10n.monthMayAbbrev, l10n.monthJunAbbrev,
      l10n.monthJulAbbrev, l10n.monthAugAbbrev, l10n.monthSepAbbrev,
      l10n.monthOctAbbrev, l10n.monthNovAbbrev, l10n.monthDecAbbrev,
    ];
    String? dateStr;
    if (event.startDatetime != null) {
      final dt = DateTime.tryParse(event.startDatetime!);
      if (dt != null) {
        dateStr = '${dt.day} ${months[dt.month]} ${dt.year}';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorStart.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Gradient icon strip
              Container(
                width: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorStart, colorEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.event_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 30,
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  color: AppColors.surfaceElevated,
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                height: 1.25,
                              ),
                            ),
                            if (dateStr != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 11, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onUnsave,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFEC4899),
                            size: 17,
                          ),
                        ),
                      ),
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
}
