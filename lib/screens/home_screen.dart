import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/app_theme.dart';
import '../models/app_class.dart';
import '../models/app_event.dart';
import '../models/app_category.dart';
import '../models/app_notification.dart';
import '../models/organization.dart';
import '../services/api_service.dart';
import '../services/saved_activities.dart';
import 'search_screen.dart';
import 'activity_details_screen.dart';
import 'notifications_screen.dart';
import 'see_all_screen.dart';
import 'see_all_events_screen.dart';
import 'see_all_orgs_screen.dart';
import 'filters_screen.dart';
import 'org_profile_screen.dart';
import 'city_picker_screen.dart';
import 'category_screen.dart';
import '../services/places_service.dart';
import 'event_details_screen.dart';
import '../l10n/app_localizations.dart';

// ─── Data classes ─────────────────────────────────────────────────────────────

class _Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  const _Category({required this.id, required this.name, required this.icon, required this.color});
}

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
  final String? categoryId;
  final Color colorStart;
  final Color colorEnd;
  final IconData icon;
  const _Banner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.categoryId,
    required this.colorStart,
    required this.colorEnd,
    required this.icon,
  });
}


// ─── Home screen ──────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AppClass> _apiClasses = [];
  List<AppEvent> _apiEvents = [];
  List<_Category> _apiCategories = [];
  List<Organization> _apiOrganizations = [];
  bool _loadingClasses = true;
  int _unreadCount = 0;
  String? _locationCity;
  double? _fetchedLat;
  double? _fetchedLng;
  int _fetchVersion = 0; // incremented each time _fetchData starts; stale results are dropped

  static const _gradients = [
    (Color(0xFF7C3AED), Color(0xFF3B82F6)),
    (Color(0xFF059669), Color(0xFF0EA5E9)),
    (Color(0xFFFF6B35), Color(0xFFEC4899)),
    (Color(0xFFEC4899), Color(0xFF7C3AED)),
  ];
  static const _icons = [
    Icons.self_improvement_rounded,
    Icons.sports_soccer_rounded,
    Icons.palette_rounded,
    Icons.music_note_rounded,
    Icons.precision_manufacturing_rounded,
    Icons.theater_comedy_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  /// Tries GPS (up to 8 s), then fires a single _fetchData with whatever
  /// coordinates we have.  Falls back gracefully if GPS is denied/unavailable.
  Future<void> _initLoad() async {
    double? lat, lng;
    String? city;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
        ).timeout(const Duration(seconds: 8));
        lat = pos.latitude;
        lng = pos.longitude;
        final marks = await placemarkFromCoordinates(lat, lng);
        if (marks.isNotEmpty) {
          city = marks.first.locality ??
              marks.first.subAdministrativeArea ??
              marks.first.administrativeArea;
        }
        if (mounted && city != null && city.isNotEmpty) {
          setState(() => _locationCity = city);
        }
      }
    } catch (_) {
      // GPS unavailable or timed out — proceed without coordinates
    }
    _fetchData(city: city, userLat: lat, userLng: lng);
  }

  static _Category _categoryFromAppCat(AppCategory c) {
    switch (c.name.toLowerCase()) {
      case 'art': return _Category(id: c.id, name: c.name, icon: Icons.palette_rounded, color: const Color(0xFFE040FB));
      case 'sport': return _Category(id: c.id, name: c.name, icon: Icons.sports_soccer_rounded, color: const Color(0xFF4CAF50));
      case 'music': return _Category(id: c.id, name: c.name, icon: Icons.music_note_rounded, color: const Color(0xFFFF9100));
      case 'education': return _Category(id: c.id, name: c.name, icon: Icons.menu_book_rounded, color: const Color(0xFF40C4FF));
      case 'theater': return _Category(id: c.id, name: c.name, icon: Icons.theater_comedy_rounded, color: const Color(0xFFFF4081));
      case 'dance': return _Category(id: c.id, name: c.name, icon: Icons.self_improvement_rounded, color: const Color(0xFFEC4899));
      default:
        if (c.name.toLowerCase().contains('master')) {
          return _Category(id: c.id, name: c.name, icon: Icons.workspace_premium_rounded, color: const Color(0xFFFFD740));
        }
        return _Category(id: c.id, name: c.name, icon: Icons.category_rounded, color: const Color(0xFF9CA3AF));
    }
  }

  Future<void> _fetchData({String? city, double? userLat, double? userLng}) async {
    _fetchedLat = userLat;
    _fetchedLng = userLng;
    final version = ++_fetchVersion;
    try {
      final results = await Future.wait([
        ApiService.getClasses(city: city, userLat: userLat, userLng: userLng),
        ApiService.getEvents(city: city, userLat: userLat, userLng: userLng),
        ApiService.getCategories(),
        ApiService.getNotifications(),
        ApiService.getFavorites(),
        ApiService.getOrganizations(city: city, userLat: userLat, userLng: userLng),
      ]);
      if (mounted && version == _fetchVersion) {
        final classes = results[0] as List<AppClass>;
        final favs = results[4] as List;
        // Populate favorites cache (separate by entity_type)
        favoriteIds.clear();
        orgFavoriteIds.clear();
        eventFavoriteIds.clear();
        final classFavIds = <String>{};
        final orgFavIdSet = <String>{};
        final eventFavIdSet = <String>{};
        for (final f in favs) {
          if (f.entityType == 'organization') {
            orgFavoriteIds[f.entityId] = f.id;
            orgFavIdSet.add(f.entityId);
          } else if (f.entityType == 'event') {
            eventFavoriteIds[f.entityId] = f.id;
            eventFavIdSet.add(f.entityId);
          } else {
            favoriteIds[f.entityId] = f.id;
            classFavIds.add(f.entityId);
          }
        }
        savedOrgIds.value = orgFavIdSet;
        savedEventIds.value = eventFavIdSet;
        savedActivities.value = classes
            .where((c) => classFavIds.contains(c.id))
            .toList()
            .asMap()
            .entries
            .map((e) {
              final g = _gradients[e.key % _gradients.length];
              return SavedActivity(
                classId: e.value.id,
                name: e.value.title,
                studio: e.value.organizationName,
                category: e.value.category,
                rating: e.value.averageRating,
                reviewCount: e.value.reviewCount,
                colorStart: g.$1,
                colorEnd: g.$2,
                icon: _icons[e.key % _icons.length],
              );
            })
            .toList();

        setState(() {
          _apiClasses = classes;
          _apiEvents = results[1] as List<AppEvent>;
          _apiCategories = (results[2] as List<AppCategory>)
              .map(_categoryFromAppCat)
              .toList();
          final notifs = results[3] as List<AppNotification>;
          _unreadCount = notifs.where((n) => !n.isRead).length;
          _apiOrganizations = results[5] as List<Organization>;
        });
      }
    } catch (_) {
    } finally {
      if (mounted && version == _fetchVersion) setState(() => _loadingClasses = false);
    }
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final notifs = await ApiService.getNotifications();
      if (mounted) setState(() => _unreadCount = notifs.where((n) => !n.isRead).length);
    } catch (_) {}
  }

  // GPS init is now done once in _initLoad().
  // This method is kept only for the "re-detect location" button if added later.

  Future<void> _openCityPicker() async {
    final selection = await Navigator.of(context).push<CitySelection>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, _, _) => CityPickerScreen(initialCity: _locationCity),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    if (selection != null && mounted) {
      setState(() => _locationCity = selection.name);
      _fetchData(
        city: selection.name,
        userLat: selection.latitude,
        userLng: selection.longitude,
      );
    }
  }

  List<_Activity> _toDisplay(List<AppClass> src) {
    return src.asMap().entries.map((e) {
      final i = e.key;
      final c = _gradients[i % _gradients.length];
      return _Activity(
        id: e.value.id,
        name: e.value.title,
        studio: e.value.organizationName,
        categoryId: e.value.categoryId,
        category: e.value.category,
        rating: e.value.averageRating,
        reviewCount: e.value.reviewCount,
        colorStart: c.$1,
        colorEnd: c.$2,
        icon: _icons[i % _icons.length],
      );
    }).toList();
  }

  void _onCategoryTap(String name, String id) {
    final cat = _apiCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => _Category(id: id, name: name, icon: Icons.category_rounded, color: AppColors.purple),
    );
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => CategoryScreen(
          categoryId: id,
          categoryName: name,
          categoryIcon: cat.icon,
          categoryColor: cat.color,
          classes: _apiClasses.where((c) => c.categoryId == id).toList(),
          events: _apiEvents.where((e) => e.categoryId == id).toList(),
          userLat: _fetchedLat,
          userLng: _fetchedLng,
        ),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEmptyActivities() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.explore_off_rounded, color: AppColors.textMuted, size: 32),
            ),
            const SizedBox(height: 16),
            Text(l10n.noActivitiesYet,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(l10n.checkBackSoonActivities,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrgs() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.business_rounded, color: AppColors.textMuted, size: 28),
            ),
            const SizedBox(height: 12),
            Text(l10n.noOrgsYet,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(l10n.checkBackSoonOrgs,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final popular = _toDisplay(_apiClasses.take(10).toList());
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      unreadCount: _unreadCount,
                      locationCity: _locationCity,
                      onTapLocation: _openCityPicker,
                      onNotificationsOpened: _refreshUnreadCount,
                    ),
                    const SizedBox(height: 20),
                    const _SearchBar(),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              _SectionHeader(
                title: l10n.eventsSection,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                onSeeAll: () => Navigator.of(context).push(PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (_, _, _) => SeeAllEventsScreen(city: _locationCity),
                  transitionsBuilder: (_, anim, _, child) => SlideTransition(
                    position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                    child: child,
                  ),
                )),
              ),
              const SizedBox(height: 16),
              _BannersSection(apiEvents: _apiEvents.take(10).toList()),
              const SizedBox(height: 28),
              _SectionHeader(
                title: l10n.categories,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                showSeeAll: false,
              ),
              const SizedBox(height: 16),
              _CategoriesRow(
                selected: null,
                onSelect: _onCategoryTap,
                categories: _apiCategories,
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                title: l10n.popularNearYou,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                onSeeAll: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (_, _, _) => SeeAllScreen(title: l10n.popularNearYou),
                    transitionsBuilder: (_, animation, _, child) => SlideTransition(
                      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                      child: child,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _loadingClasses
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : popular.isEmpty
                      ? _buildEmptyActivities()
                      : _ActivityRow(activities: popular),
              const SizedBox(height: 28),
              _SectionHeader(
                title: l10n.organizationsNearYou,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                onSeeAll: () => Navigator.of(context).push(PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (_, _, _) => SeeAllOrgsScreen(city: _locationCity),
                  transitionsBuilder: (_, anim, _, child) => SlideTransition(
                    position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                    child: child,
                  ),
                )),
              ),
              const SizedBox(height: 16),
              _loadingClasses
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _apiOrganizations.isEmpty
                      ? _buildEmptyOrgs()
                      : _OrgsRow(orgs: _apiOrganizations.take(10).toList(), city: _locationCity),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int unreadCount;
  final String? locationCity;
  final VoidCallback onTapLocation;
  final VoidCallback onNotificationsOpened;
  const _Header({
    required this.unreadCount,
    required this.locationCity,
    required this.onTapLocation,
    required this.onNotificationsOpened,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.2), width: 1),
          ),
          child: const Icon(Icons.location_on_rounded, color: AppColors.purple, size: 16),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onTapLocation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.yourLocation,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.3)),
              Row(
                children: [
                  Text(
                    locationCity ?? AppLocalizations.of(context)!.detectingLocation,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: locationCity != null ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (ctx, anim, secAnim) => const NotificationsScreen(),
              transitionsBuilder: (ctx, anim, secAnim, child) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                    .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ).then((_) => onNotificationsOpened()),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.divider, width: 1),
                ),
                child: const Icon(Icons.notifications_rounded, color: AppColors.textPrimary, size: 22),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (ctx, anim, sec) => const SearchScreen(),
                transitionsBuilder: (ctx, anim, sec, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 220),
              ),
            ),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.searchHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 350),
              pageBuilder: (_, _, _) => const FiltersScreen(),
              transitionsBuilder: (_, animation, _, child) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
          ),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: AppColors.purple.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsets padding;
  final bool showSeeAll;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    this.padding = EdgeInsets.zero,
    this.showSeeAll = true,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(title,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          if (showSeeAll)
            GestureDetector(
              onTap: onSeeAll ?? () {},
              child: ShaderMask(
                shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                child: Text(AppLocalizations.of(context)!.btnSeeAll,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Banners ──────────────────────────────────────────────────────────────────

class _BannersSection extends StatelessWidget {
  final List<AppEvent> apiEvents;
  const _BannersSection({required this.apiEvents});

  static const _styles = [
    (Color(0xFFFF6B35), Color(0xFFEC4899), Icons.wb_sunny_rounded),
    (Color(0xFF7C3AED), Color(0xFF3B82F6), Icons.code_rounded),
    (Color(0xFF059669), Color(0xFF0EA5E9), Icons.weekend_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    if (apiEvents.isEmpty) return const SizedBox.shrink();

    final banners = apiEvents.asMap().entries.map((e) {
      final s = _styles[e.key % _styles.length];
      return _Banner(
        id: e.value.id,
        title: e.value.title,
        subtitle: e.value.subtitle,
        badge: e.value.badge,
        categoryId: e.value.categoryId,
        colorStart: s.$1,
        colorEnd: s.$2,
        icon: s.$3,
      );
    }).toList();

    return SizedBox(
      height: 168,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: banners.length,
        itemBuilder: (context, i) => _BannerCard(banner: banners[i]),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final _Banner banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, _, _) => EventDetailsScreen(
            eventId: banner.id,
            colorStart: banner.colorStart,
            colorEnd: banner.colorEnd,
            icon: banner.icon,
          ),
          transitionsBuilder: (_, animation, _, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
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
            BoxShadow(color: banner.colorStart.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24, top: -24,
              child: Container(width: 110, height: 110,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08))),
            ),
            Positioned(
              right: 24, bottom: -32,
              child: Container(width: 88, height: 88,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06))),
            ),
            Positioned(
              right: 20, top: 20,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
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
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 8),
                  Text(banner.title,
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
                  const SizedBox(height: 4),
                  Text(banner.subtitle,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Categories ───────────────────────────────────────────────────────────────

class _CategoriesRow extends StatelessWidget {
  final String? selected;
  final void Function(String name, String id) onSelect;
  final List<_Category> categories;

  const _CategoriesRow({required this.selected, required this.onSelect, required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox(height: 96);
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          return _CategoryItem(
            category: cat,
            isSelected: selected == cat.name,
            onTap: () => onSelect(cat.name, cat.id),
          );
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final _Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({required this.category, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 18),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? category.color.withValues(alpha: 0.25)
                    : category.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? category.color : category.color.withValues(alpha: 0.3),
                  width: isSelected ? 2.5 : 1.5,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: category.color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Icon(category.icon,
                  color: isSelected ? category.color : category.color.withValues(alpha: 0.8), size: 26),
            ),
            const SizedBox(height: 7),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Activity cards ───────────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  final List<_Activity> activities;
  const _ActivityRow({required this.activities});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 248,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: activities.length,
        itemBuilder: (context, i) => _ActivityCard(activity: activities[i]),
      ),
    );
  }
}

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
    if (mounted) {
      setState(() => _isSaved = isSavedById(widget.activity.id));
    }
  }

  Future<void> _toggle() async {
    if (_toggling || widget.activity.id.isEmpty) return;
    setState(() {
      _toggling = true;
      _isSaved = !_isSaved;
    });

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
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
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
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1))),
                    ),
                    Center(
                      child: Icon(widget.activity.icon, size: 44, color: Colors.white.withValues(alpha: 0.35)),
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
                            style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3)),
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: _toggle,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                            color: _isSaved ? const Color(0xFFFFD700) : Colors.white,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(widget.activity.studio,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFD700)),
                      const SizedBox(width: 3),
                      Text(widget.activity.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(width: 4),
                      Text('(${widget.activity.reviewCount})',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty category state ─────────────────────────────────────────────────────


// ─── Organizations section ────────────────────────────────────────────────────

class _OrgsRow extends StatelessWidget {
  final List<Organization> orgs;
  final String? city;
  const _OrgsRow({required this.orgs, this.city});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 156,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: orgs.length,
        itemBuilder: (ctx, i) => _OrgCard(org: orgs[i]),
      ),
    );
  }
}

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
      onTap: () => Navigator.of(context).push(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => OrgProfileScreen(
          orgId: org.id,
          name: org.name,
          colorStart: g.$1,
          colorEnd: g.$2,
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [g.$1, g.$2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
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

// ─── Active filter bar ────────────────────────────────────────────────────────

