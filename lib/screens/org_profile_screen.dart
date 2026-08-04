import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/organization.dart';
import '../models/org_photo.dart';
import '../models/event_recurrence.dart';
import '../services/api_service.dart';
import '../services/saved_activities.dart';
import 'activity_details_screen.dart';
import 'photo_viewer_screen.dart';
import 'chat_screen.dart';
import 'event_details_screen.dart';
import 'reviews_screen.dart';
import 'write_review_screen.dart';
import '../routing/transitions.dart';
import '../utils/event_grouping.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _orgInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}

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

// ─── Screen ───────────────────────────────────────────────────────────────────

class OrgProfileScreen extends StatefulWidget {
  final String? orgId;
  final String name;
  final Color colorStart;
  final Color colorEnd;
  final String category;
  final double rating;
  final int reviewCount;

  const OrgProfileScreen({
    super.key,
    this.orgId,
    required this.name,
    required this.colorStart,
    required this.colorEnd,
    required this.category,
    this.rating = 0,
    this.reviewCount = 0,
  });

  @override
  State<OrgProfileScreen> createState() => _OrgProfileScreenState();
}

class _OrgProfileScreenState extends State<OrgProfileScreen> {
  Map<String, dynamic>? _orgData;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _events = [];
  double _avgRating = 0;
  int _reviewCount = 0;
  List<Map<String, dynamic>> _reviews = [];
  List<OrgPhoto> _photos = [];
  bool _startingChat = false;
  bool _isSaved = false;
  bool _savingInProgress = false;

  @override
  void initState() {
    super.initState();
    _avgRating = widget.rating;
    _reviewCount = widget.reviewCount;
    if (widget.orgId != null) {
      _isSaved = isOrgSaved(widget.orgId!);
      savedOrgIds.addListener(_onSavedChanged);
      _loadData();
    }
  }

  void _onSavedChanged() {
    if (mounted && widget.orgId != null) {
      setState(() => _isSaved = isOrgSaved(widget.orgId!));
    }
  }

  @override
  void dispose() {
    savedOrgIds.removeListener(_onSavedChanged);
    super.dispose();
  }

  Future<void> _toggleSave() async {
    final orgId = widget.orgId;
    if (orgId == null || _savingInProgress) return;
    _savingInProgress = true;
    try {
      if (_isSaved) {
        final favId = orgFavoriteIds[orgId];
        removeSavedOrg(orgId);
        if (favId != null) {
          try {
            await ApiService.removeFavorite(favId);
          } catch (_) {
            addSavedOrg(_buildOrg(orgId), favId); // rollback
          }
        }
      } else {
        final org = _buildOrg(orgId);
        try {
          final fav = await ApiService.addOrgFavorite(orgId);
          addSavedOrg(org, fav.id);
        } catch (_) {}
      }
    } finally {
      _savingInProgress = false;
    }
  }

  Organization _buildOrg(String orgId) {
    return Organization(
      id: orgId,
      name: _displayName,
      city: _orgData?['city']?.toString(),
      address: _orgData?['address']?.toString(),
      description: _orgData?['description']?.toString(),
      logoUrl: _orgData?['logo_url']?.toString(),
      category: widget.category.isNotEmpty ? widget.category : null,
      averageRating: _avgRating,
      reviewCount: _reviewCount,
    );
  }

  Future<void> _loadData() async {
    final orgIdInt = int.tryParse(widget.orgId!);

    // Load org info, classes and events in parallel
    try {
      final futures = <Future>[
        ApiService.getOrganization(widget.orgId!),
        ApiService.getOrgClasses(widget.orgId!),
        ApiService.getPublicOrgEvents(widget.orgId!),
      ];
      final results = await Future.wait(
        futures.map((f) => f.catchError((_) => null)),
      );
      if (!mounted) return;
      final org = results[0] as Map<String, dynamic>?;
      final classes = (results[1] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final events = (results[2] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        if (org != null) _orgData = org;
        _classes = classes;
        _events = events;
      });
    } catch (_) {}

    // Load photos
    if (widget.orgId != null) {
      try {
        final photos = await ApiService.getOrgPhotos(widget.orgId!);
        if (!mounted) return;
        setState(() => _photos = photos);
      } catch (_) {}
    }

    // Load reviews separately so a failure here never hides the org data
    if (orgIdInt != null) {
      try {
        final reviews = await ApiService.getReviews(orgIdInt);
        if (!mounted) return;
        double avgRating = _avgRating;
        if (reviews.isNotEmpty) {
          avgRating =
              reviews.fold<double>(
                0,
                (s, r) => s + ((r['rating'] ?? 0) as num).toDouble(),
              ) /
              reviews.length;
        }
        setState(() {
          _reviews = reviews;
          _reviewCount = reviews.length;
          _avgRating = avgRating;
        });
      } catch (_) {}
    }
  }

  Future<void> _reloadReviews() async {
    final orgIdInt = int.tryParse(widget.orgId!);
    if (orgIdInt == null) return;
    try {
      final reviews = await ApiService.getReviews(orgIdInt);
      if (!mounted) return;
      double avgRating = _avgRating;
      if (reviews.isNotEmpty) {
        avgRating =
            reviews.fold<double>(
              0,
              (s, r) => s + ((r['rating'] ?? 0) as num).toDouble(),
            ) /
            reviews.length;
      }
      setState(() {
        _reviews = reviews;
        _reviewCount = reviews.length;
        _avgRating = avgRating;
      });
    } catch (_) {}
  }

  String get _displayName => (_orgData?['name'] as String?) ?? widget.name;
  String get _initials => _orgInitials(_displayName);
  String? get _website => _orgData?['website'] as String?;
  String? get _address {
    final addr = _orgData?['address'] as String?;
    final legacyCity = _orgData?['city'] as String?;
    String? city;
    if (legacyCity != null && legacyCity.isNotEmpty) {
      city = legacyCity;
    } else {
      final locale = Localizations.localeOf(context).languageCode;
      city = switch (locale) {
        'he' => _orgData?['city_name_he'] as String?,
        'ru' => _orgData?['city_name_ru'] as String?,
        _ => _orgData?['city_name_en'] as String?,
      };
    }
    if (addr == null && (city == null || city.isEmpty)) return null;
    return [addr, city].where((s) => s != null && s.isNotEmpty).join(', ');
  }

  String? get _description => _orgData?['description'] as String?;
  String? get _instagramUrl => _orgData?['instagram_url'] as String?;
  String? get _facebookUrl => _orgData?['facebook_url'] as String?;

  Future<void> _openMessage(BuildContext context) async {
    final orgIdStr = widget.orgId;
    final orgIdInt = orgIdStr != null ? int.tryParse(orgIdStr) : null;
    if (orgIdInt == null) {
      _goChat(context, null);
      return;
    }
    setState(() => _startingChat = true);
    try {
      final convo = await ApiService.createConversation(orgIdInt);
      if (!mounted) return;
      _goChat(context, convo['id']?.toString());
    } catch (_) {
      if (mounted) _goChat(context, null);
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  void _goChat(BuildContext context, String? conversationId) {
    Navigator.of(context).push(
      slideRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          name: _displayName,
          initials: _initials.isNotEmpty ? _initials : '?',
          avatarColor: widget.colorStart,
        ),
      ),
    );
  }

  Future<void> _openSocial(String rawValue, String baseUrl) async {
    final trimmed = rawValue.trim().replaceFirst(RegExp(r'^@'), '');
    final url = trimmed.startsWith('http') ? trimmed : '$baseUrl$trimmed';
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _openWebsite(BuildContext context, String url) async {
    final normalized = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.parse(normalized);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              url,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCover(),
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrgInfo(),
                      const SizedBox(height: 20),
                      _buildActionRow(context),
                      if (_orgData?['trial_lesson_available'] == true) ...[
                        const SizedBox(height: 28),
                        Container(height: 1, color: AppColors.divider),
                        const SizedBox(height: 24),
                        _buildTrialSection(),
                      ],
                      if (_photos.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Container(height: 1, color: AppColors.divider),
                        const SizedBox(height: 24),
                        _buildPhotosSection(context),
                      ],
                      const SizedBox(height: 28),
                      Container(height: 1, color: AppColors.divider),
                      const SizedBox(height: 24),
                      _buildClassesSection(context),
                      const SizedBox(height: 24),
                      Container(height: 1, color: AppColors.divider),
                      const SizedBox(height: 24),
                      _buildEventsSection(),
                      const SizedBox(height: 24),
                      Container(height: 1, color: AppColors.divider),
                      const SizedBox(height: 24),
                      _buildReviewsSection(context),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    _HeaderBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    if (widget.orgId != null) ...[
                      _HeartBtn(isSaved: _isSaved, onTap: _toggleSave),
                      const SizedBox(width: 8),
                    ],
                    _HeaderBtn(icon: Icons.share_rounded, onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cover + avatar ───────────────────────────────────────────────────────────

  Widget _buildCover() {
    final bannerUrl = _orgData?['banner_url'] as String?;
    final logoUrl = _orgData?['logo_url'] as String?;
    final hasBanner = bannerUrl != null && bannerUrl.isNotEmpty;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.colorStart, widget.colorEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              if (hasBanner)
                Image.network(
                  bannerUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                )
              else ...[
                Positioned(
                  right: -60,
                  top: -60,
                  child: Container(
                    width: 220,
                    height: 220,
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
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.business_rounded,
                    size: 72,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          bottom: -44,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [widget.colorStart, widget.colorEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppColors.background, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: widget.colorStart.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: hasLogo
                  ? ClipOval(
                      child: Image.network(
                        logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            _initials.isNotEmpty ? _initials : '?',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _initials.isNotEmpty ? _initials : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Org info ─────────────────────────────────────────────────────────────────

  Widget _buildOrgInfo() {
    final address = _address;
    final description = _description;
    return Column(
      children: [
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _displayName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.purple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: widget.colorStart.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.colorStart.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              widget.category,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.colorStart,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stars(_avgRating, size: 17),
            const SizedBox(width: 6),
            Text(
              _reviewCount > 0 ? _avgRating.toStringAsFixed(1) : '—',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($_reviewCount reviews)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(height: 1, color: AppColors.divider),
        const SizedBox(height: 14),
        if (address != null && address.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  address,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (description != null && description.isNotEmpty)
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),
        if ((_instagramUrl?.isNotEmpty ?? false) ||
            (_facebookUrl?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (_instagramUrl?.isNotEmpty ?? false)
                _SocialIcon(
                  icon: FontAwesomeIcons.instagram,
                  color: const Color(0xFFE1306C),
                  gradientColors: const [
                    Color(0xFFF58529),
                    Color(0xFFDD2A7B),
                    Color(0xFF8134AF),
                  ],
                  onTap: () =>
                      _openSocial(_instagramUrl!, 'https://instagram.com/'),
                ),
              if ((_instagramUrl?.isNotEmpty ?? false) &&
                  (_facebookUrl?.isNotEmpty ?? false))
                const SizedBox(width: 10),
              if (_facebookUrl?.isNotEmpty ?? false)
                _SocialIcon(
                  icon: FontAwesomeIcons.facebookF,
                  color: const Color(0xFF1877F2),
                  gradientColors: const [Color(0xFF1877F2), Color(0xFF0C5FCC)],
                  onTap: () =>
                      _openSocial(_facebookUrl!, 'https://facebook.com/'),
                ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Action buttons ───────────────────────────────────────────────────────────

  Widget _buildActionRow(BuildContext context) {
    final website = _website;
    return Row(
      children: [
        Expanded(
          child: _startingChat
              ? Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.colorStart, widget.colorEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : _ActionBtn(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Message',
                  isGradient: true,
                  colorStart: widget.colorStart,
                  colorEnd: widget.colorEnd,
                  onTap: () => _openMessage(context),
                ),
        ),
        if (website != null && website.isNotEmpty) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _ActionBtn(
              icon: Icons.language_rounded,
              label: 'Website',
              onTap: () => _openWebsite(context, website),
            ),
          ),
        ],
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: Icons.directions_rounded,
            label: 'Directions',
            onTap: _address != null && _address!.isNotEmpty
                ? () async {
                    final uri = Uri.parse(
                      'https://maps.google.com/?q=${Uri.encodeComponent(_address!)}',
                    );
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                : null,
          ),
        ),
      ],
    );
  }

  // ── Photos ───────────────────────────────────────────────────────────────────

  Widget _buildPhotosSection(BuildContext context) {
    final urls = _photos.map((p) => p.photoUrl).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Photos'),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final photo = _photos[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PhotoViewerScreen(photoUrls: urls, initialIndex: i),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: _OrgPhotoThumbnail(url: photo.photoUrl),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Trial Lesson ─────────────────────────────────────────────────────────────

  Widget _buildTrialSection() {
    final price = _orgData?['trial_lesson_price'];
    final comment = _orgData?['trial_lesson_comment'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Trial Lesson'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Trial lesson available',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (price != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '₪${price is double ? price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2) : price}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
              ],
              if (comment != null && comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  comment,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Classes ──────────────────────────────────────────────────────────────────

  Widget _buildClassesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Our Classes'),
        const SizedBox(height: 14),
        if (_classes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'No classes available yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          ...List.generate(_classes.length, (i) {
            final cls = _classes[i];
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < _classes.length - 1 ? 10 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  final classId = cls['id']?.toString();
                  if (classId == null) return;
                  Navigator.of(context).push(
                    slideRoute(
                      builder: (_) => ActivityDetailsScreen(
                        classId: classId,
                        name: (cls['name'] ?? '').toString(),
                        studio: _displayName,
                        category: widget.category,
                        colorStart: widget.colorStart,
                        colorEnd: widget.colorEnd,
                        heroIcon: Icons.school_rounded,
                      ),
                    ),
                  );
                },
                child: _ClassTile(
                  cls: cls,
                  colorStart: widget.colorStart,
                  colorEnd: widget.colorEnd,
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── Events ───────────────────────────────────────────────────────────────────

  Widget _buildEventsSection() {
    final grouped = groupRawEventsBySeries(_events);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Upcoming Events'),
        const SizedBox(height: 14),
        if (grouped.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'No upcoming events',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          ...List.generate(grouped.length, (i) {
            final ev = grouped[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < grouped.length - 1 ? 10 : 0),
              child: GestureDetector(
                onTap: () {
                  final eventId = ev['id']?.toString();
                  if (eventId == null) return;
                  Navigator.of(context).push(
                    slideRoute(
                      builder: (_) => EventDetailsScreen(
                        eventId: eventId,
                        colorStart: widget.colorStart,
                        colorEnd: widget.colorEnd,
                      ),
                    ),
                  );
                },
                child: _EventTile(event: ev),
              ),
            );
          }),
      ],
    );
  }

  // ── Reviews ──────────────────────────────────────────────────────────────────

  Widget _buildReviewsSection(BuildContext context) {
    final orgIdInt = widget.orgId != null ? int.tryParse(widget.orgId!) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reviews',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                slideRoute(
                  builder: (_) => ReviewsScreen(
                    activityName: _displayName,
                    rating: _avgRating,
                    reviewCount: _reviewCount,
                    colorStart: widget.colorStart,
                    colorEnd: widget.colorEnd,
                    organizationId: orgIdInt,
                    allowWrite: true,
                  ),
                ),
              ),
              child: ShaderMask(
                shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                child: Text(
                  'See All',
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
        const SizedBox(height: 14),
        _RatingSummaryCard(rating: _avgRating, reviewCount: _reviewCount),
        if (_reviews.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'No reviews yet',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          ..._reviews.take(2).map((r) => _OrgReviewCard(review: r)),
        ],
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final orgIdInt = widget.orgId != null
                ? int.tryParse(widget.orgId!)
                : null;
            await Navigator.of(context).push(
              modalRoute(
                builder: (_) => WriteReviewScreen(
                  activityName: _displayName,
                  colorStart: widget.colorStart,
                  colorEnd: widget.colorEnd,
                  organizationId: orgIdInt,
                ),
              ),
            );
            _reloadReviews();
          },
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.purple, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.rate_review_rounded,
                  size: 18,
                  color: AppColors.purple,
                ),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.brandGradient.createShader(b),
                  child: Text(
                    'Write a Review',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrgPhotoThumbnail extends StatelessWidget {
  final String url;
  const _OrgPhotoThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    final isLocal = url.startsWith('/') || url.startsWith('file://');
    if (isLocal) {
      final path = url.startsWith('file://') ? url.substring(7) : url;
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (ctx, child, progress) =>
          progress == null ? child : _loading(),
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _loading() => Container(
    color: AppColors.surfaceElevated,
    child: const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.purple,
        ),
      ),
    ),
  );

  Widget _placeholder() => Container(
    color: AppColors.surfaceElevated,
    child: const Icon(
      Icons.image_outlined,
      color: AppColors.textMuted,
      size: 30,
    ),
  );
}

class _OrgReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _OrgReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] ?? 0) as num;
    final comment = (review['comment'] ?? '').toString();
    final reviewerName =
        (review['reviewer_name'] ?? review['user_name'] ?? 'Anonymous')
            .toString();
    final createdAt = review['created_at']?.toString() ?? '';
    String dateStr = '';
    try {
      if (createdAt.isNotEmpty) {
        final dt = DateTime.parse(createdAt);
        dateStr = '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {}

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
                    reviewerName.isNotEmpty
                        ? reviewerName[0].toUpperCase()
                        : '?',
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
}

// ─── Header buttons ───────────────────────────────────────────────────────────

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});

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
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _HeartBtn extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;
  const _HeartBtn({required this.isSaved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSaved
              ? const Color(0xFFEC4899).withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isGradient;
  final Color? colorStart;
  final Color? colorEnd;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.isGradient = false,
    this.colorStart,
    this.colorEnd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isGradient) {
      return GestureDetector(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorStart!, colorEnd!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colorStart!.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
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

// ─── Class tile ───────────────────────────────────────────────────────────────

class _ClassTile extends StatelessWidget {
  final Map<String, dynamic> cls;
  final Color colorStart;
  final Color colorEnd;

  const _ClassTile({
    required this.cls,
    required this.colorStart,
    required this.colorEnd,
  });

  @override
  Widget build(BuildContext context) {
    final name = (cls['name'] ?? 'Unnamed Class').toString();
    final description = (cls['description'] ?? '').toString();
    final price = cls['price'];
    final ageMin = cls['age_min'];
    final ageMax = cls['age_max'];
    String? ageRange;
    if (ageMin != null || ageMax != null) {
      ageRange = '${ageMin ?? '?'}–${ageMax ?? '?'} yrs';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorStart, colorEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (ageRange != null) ...[
                      _Chip(
                        label: ageRange,
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (price != null)
                      _Chip(
                        label: '₪${(price as num).toStringAsFixed(0)}',
                        icon: Icons.attach_money_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Event tile ───────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final name = (event['title'] ?? event['name'] ?? 'Unnamed Event')
        .toString();
    final description = (event['description'] ?? '').toString();
    final startDt = event['start_datetime'];
    String? dateStr;
    if (startDt != null) {
      try {
        final dt = DateTime.parse(startDt.toString());
        final timeStr =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        dateStr = '${dt.day} ${_monthName(dt.month)} ${dt.year} · $timeStr';
      } catch (_) {
        dateStr = startDt.toString();
      }
    }
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final String cityLabel;
    if (event['is_nationwide'] == true) {
      cityLabel = l10n.nationwideLabel;
    } else {
      final raw = switch (locale) {
        'he' => event['city_name_he'],
        'ru' => event['city_name_ru'],
        _ => event['city_name_en'],
      };
      cityLabel = (raw ?? event['city'] ?? '').toString();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_rounded,
              size: 20,
              color: AppColors.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                if (dateStr != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
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
                if (cityLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 11,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          cityLabel,
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
                if (event['series_id'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.repeat_rounded,
                        size: 11,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        event['recurrence'] != null
                            ? recurrenceFrequencyText(
                                EventRecurrence.fromJson(
                                  event['recurrence'] as Map<String, dynamic>,
                                ),
                                l10n,
                              )
                            : l10n.repeatsWeekly,
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
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}

// ─── Small chip ───────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Social icon button ───────────────────────────────────────────────────────

class _SocialIcon extends StatelessWidget {
  final FaIconData icon;
  final Color color;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.color,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: FaIcon(icon, size: 18, color: Colors.white)),
      ),
    );
  }
}

// ─── Rating summary card ──────────────────────────────────────────────────────

class _RatingSummaryCard extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const _RatingSummaryCard({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              reviewCount > 0 ? rating.toStringAsFixed(1) : '—',
              style: GoogleFonts.poppins(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _stars(reviewCount > 0 ? rating : 0, size: 14),
          const SizedBox(height: 3),
          Text(
            '$reviewCount reviews',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
