import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/app_event.dart';
import '../models/event_recurrence.dart';
import '../services/api_service.dart';
import '../services/saved_activities.dart';
import '../l10n/app_localizations.dart';
import 'chat_screen.dart';
import 'org_profile_screen.dart';
import '../routing/transitions.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  final Color colorStart;
  final Color colorEnd;
  final IconData icon;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    this.colorStart = const Color(0xFF7C3AED),
    this.colorEnd = const Color(0xFFEC4899),
    this.icon = Icons.event_rounded,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  AppEvent? _event;
  bool _loading = true;
  String? _error;
  bool _isSaved = false;
  bool _savingInProgress = false;

  Map<String, dynamic>? _orgData;
  String _orgName = '';
  List<Map<String, dynamic>> _otherEvents = [];

  @override
  void initState() {
    super.initState();
    _isSaved = isEventSaved(widget.eventId);
    savedEventIds.addListener(_onSavedChanged);
    _loadEvent();
  }

  void _onSavedChanged() {
    if (mounted) setState(() => _isSaved = isEventSaved(widget.eventId));
  }

  @override
  void dispose() {
    savedEventIds.removeListener(_onSavedChanged);
    super.dispose();
  }

  Future<void> _loadEvent() async {
    try {
      final event = await ApiService.getEvent(widget.eventId);
      if (!mounted) return;
      setState(() => _event = event);

      // Load org + other events in parallel
      final orgId = event.organizationId;
      if (orgId != null) {
        final orgFuture = ApiService.getOrganization(orgId.toString());
        final eventsFuture = ApiService.getOrgEvents(orgId.toString());
        final results = await Future.wait([orgFuture, eventsFuture]);
        if (!mounted) return;
        final org = results[0] as Map<String, dynamic>;
        final allEvents = results[1] as List<Map<String, dynamic>>;
        setState(() {
          _orgData = org;
          _orgName = (org['name'] as String?) ?? '';
          _otherEvents = allEvents
              .where((e) => e['id'].toString() != widget.eventId)
              .take(3)
              .toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load event');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleSave() async {
    if (_savingInProgress) return;
    _savingInProgress = true;
    try {
      if (_isSaved) {
        final favId = eventFavoriteIds[widget.eventId];
        removeSavedEvent(widget.eventId);
        if (favId != null) {
          try {
            await ApiService.removeFavorite(favId);
          } catch (_) {
            if (_event != null) addSavedEvent(_event!, favId);
          }
        }
      } else {
        final event = _event;
        if (event == null) return;
        try {
          final fav = await ApiService.addEventFavorite(widget.eventId);
          addSavedEvent(event, fav.id);
        } catch (_) {}
      }
    } finally {
      _savingInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            )
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Center(
              child: Text(
                _error!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final event = _event!;
    final orgId = event.organizationId;
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(event),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Category + badge row ──
                    _buildBadgeRow(event),
                    const SizedBox(height: 14),
                    // ── Title ──
                    Text(
                      event.title,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── Info cards: date, time, location ──
                    _buildInfoCards(event),
                    if (event.price != null) ...[
                      const SizedBox(height: 16),
                      _buildPriceCard(event),
                    ],
                    const SizedBox(height: 24),
                    _divider(),
                    const SizedBox(height: 24),
                    // ── About ──
                    _buildAboutSection(event),
                    const SizedBox(height: 24),
                    _divider(),
                    const SizedBox(height: 24),
                    // ── Details chips ──
                    if (event.minAge != null ||
                        event.maxAge != null ||
                        event.capacity != null) ...[
                      _buildDetailsSection(event),
                      const SizedBox(height: 24),
                      _divider(),
                      const SizedBox(height: 24),
                    ],
                    // ── Organization card ──
                    if (orgId != null) ...[
                      _buildOrgCard(orgId),
                      const SizedBox(height: 24),
                      _divider(),
                      const SizedBox(height: 24),
                    ],
                    // ── Other events ──
                    if (_otherEvents.isNotEmpty) ...[
                      _buildOtherEventsSection(),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 90),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildTopBar(),
            ),
          ),
        ),
        // ── Contact bottom bar ──
        if (orgId != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _ContactBar(
              orgId: orgId,
              orgName: _orgName.isNotEmpty ? _orgName : event.title,
              colorStart: widget.colorStart,
            ),
          ),
      ],
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────────

  Widget _buildHero(AppEvent event) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.colorStart, widget.colorEnd],
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
                widget.icon,
                color: Colors.white.withValues(alpha: 0.9),
                size: 54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final event = _event;
    return Row(
      children: [
        _HeaderBtn(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        _HeaderBtn(
          icon: Icons.share_rounded,
          onTap: () => Share.share(
            event != null
                ? 'Check out "${event.title}" on HobbyLab!'
                : 'Check out this event on HobbyLab!',
          ),
        ),
        const SizedBox(width: 8),
        _HeaderBtn(
          icon: _isSaved
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          onTap: _toggleSave,
          activeColor: _isSaved ? AppColors.pink : null,
        ),
      ],
    );
  }

  // ── Badge row ────────────────────────────────────────────────────────────────

  Widget _buildBadgeRow(AppEvent event) {
    return Row(
      children: [
        if (event.badge.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              event.badge,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.purpleLight,
              ),
            ),
          ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
            ),
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
    );
  }

  // ── Info cards ───────────────────────────────────────────────────────────────

  Widget _buildInfoCards(AppEvent event) {
    final items = <_InfoItem>[];

    if (event.startDatetime != null) {
      final dt = DateTime.tryParse(event.startDatetime!);
      if (dt != null) {
        items.add(
          _InfoItem(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _fmtDate(dt),
            color: const Color(0xFF0EA5E9),
          ),
        );
        items.add(
          _InfoItem(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: _fmtTime(dt),
            color: AppColors.purple,
          ),
        );
      }
    }

    final hasAddress = event.address != null && event.address!.isNotEmpty;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    String? cityLabel;
    if (event.isNationwide) {
      cityLabel = l10n.nationwideLabel;
    } else {
      cityLabel = switch (locale) {
        'he' => event.cityNameHe,
        'ru' => event.cityNameRu,
        _ => event.cityNameEn,
      };
      if (cityLabel == null || cityLabel.isEmpty) cityLabel = event.city;
    }
    if (hasAddress || (cityLabel != null && cityLabel.isNotEmpty)) {
      final loc = [
        event.address,
        cityLabel,
      ].where((s) => s != null && s.isNotEmpty).join(', ');
      items.add(
        _InfoItem(
          icon: Icons.location_on_rounded,
          label: 'Location',
          value: loc,
          color: const Color(0xFFEC4899),
        ),
      );
    }

    if (event.seriesId != null && event.recurrence != null) {
      final r = event.recurrence!;
      final freqText = recurrenceFrequencyText(r, l10n);
      final endText = recurrenceEndText(r, l10n);
      items.add(
        _InfoItem(
          icon: Icons.repeat_rounded,
          label: l10n.repeatSection,
          value: '$freqText · $endText',
          color: AppColors.purple,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          item.value,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Price ────────────────────────────────────────────────────────────────────

  Widget _buildPriceCard(AppEvent event) {
    final price = event.price!;
    final comment = event.priceComment;
    final isFree = price == 0;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFree
                      ? l10n.eventFree
                      : '₪${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.purple,
                  ),
                ),
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    comment,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── About ────────────────────────────────────────────────────────────────────

  Widget _buildAboutSection(AppEvent event) {
    return _ExpandableAbout(description: event.subtitle);
  }

  // ── Details chips ────────────────────────────────────────────────────────────

  Widget _buildDetailsSection(AppEvent event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Details'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (event.minAge != null && event.maxAge != null)
              _chip(
                'Ages ${event.minAge}–${event.maxAge}',
                AppColors.purple.withValues(alpha: 0.12),
                AppColors.purpleLight,
              ),
            if (event.capacity != null)
              _chip(
                '${event.capacity} spots',
                const Color(0xFF059669).withValues(alpha: 0.12),
                const Color(0xFF059669),
              ),
          ],
        ),
      ],
    );
  }

  // ── Org card ─────────────────────────────────────────────────────────────────

  Widget _buildOrgCard(int orgId) {
    final name = _orgName.isNotEmpty ? _orgName : 'Organization';
    final logoUrl = _orgData?['logo_url'] as String?;
    return GestureDetector(
      onTap: () => _openOrgProfile(orgId),
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
                  colors: [widget.colorStart, widget.colorEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, e, st) => Center(
                          child: Text(
                            _initials(name),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _initials(name),
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
                    name,
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
              onTap: () => _openOrgProfile(orgId),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.3),
                  ),
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
      ),
    );
  }

  void _openOrgProfile(int orgId) {
    final name = _orgName.isNotEmpty ? _orgName : 'Organization';
    Navigator.of(context).push(
      slideRoute(
        builder: (_) => OrgProfileScreen(
          orgId: orgId.toString(),
          name: name,
          colorStart: widget.colorStart,
          colorEnd: widget.colorEnd,
          category: _event?.badge ?? '',
        ),
      ),
    );
  }

  // ── Other events ─────────────────────────────────────────────────────────────

  Widget _buildOtherEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _divider(),
        const SizedBox(height: 24),
        _sectionTitle('Other Events'),
        const SizedBox(height: 14),
        ..._otherEvents.map(
          (e) => _OtherEventCard(
            event: e,
            colorStart: widget.colorStart,
            colorEnd: widget.colorEnd,
          ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _divider() => Container(height: 1, color: AppColors.divider);

  Widget _sectionTitle(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );

  Widget _chip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
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
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
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

// ─── Expandable about section ─────────────────────────────────────────────────

class _ExpandableAbout extends StatefulWidget {
  final String description;
  const _ExpandableAbout({required this.description});

  @override
  State<_ExpandableAbout> createState() => _ExpandableAboutState();
}

class _ExpandableAboutState extends State<_ExpandableAbout> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEmpty = widget.description.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.aboutSection,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isEmpty ? l10n.noDescriptionAvailable : widget.description,
          maxLines: isEmpty || _expanded ? null : 3,
          overflow: isEmpty || _expanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isEmpty ? AppColors.textMuted : AppColors.textSecondary,
            height: 1.65,
          ),
        ),
        if (!isEmpty) ...[
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
      ],
    );
  }
}

// ─── Other event card ─────────────────────────────────────────────────────────

class _OtherEventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final Color colorStart;
  final Color colorEnd;

  const _OtherEventCard({
    required this.event,
    required this.colorStart,
    required this.colorEnd,
  });

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
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
      return '${dt.day} ${months[dt.month]}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (event['title'] ?? event['name'] ?? '').toString();
    final dateStr = _fmtDate(event['start_datetime']?.toString());
    final city = (event['city'] ?? '').toString();
    final badge = (event['badge'] ?? event['status'] ?? '')
        .toString()
        .toUpperCase();

    return GestureDetector(
      onTap: () {
        final id = event['id']?.toString() ?? '';
        if (id.isEmpty) return;
        Navigator.of(context).push(
          slideRoute(
            builder: (_) => EventDetailsScreen(
              eventId: id,
              colorStart: colorStart,
              colorEnd: colorEnd,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [colorStart, colorEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.event_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (dateStr.isNotEmpty) ...[
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          dateStr,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      if (dateStr.isNotEmpty && city.isNotEmpty)
                        Text(
                          '  ·  ',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      if (city.isNotEmpty)
                        Text(
                          city,
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
            if (badge.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purpleLight,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Contact bar ─────────────────────────────────────────────────────────────

class _ContactBar extends StatefulWidget {
  final int orgId;
  final String orgName;
  final Color colorStart;

  const _ContactBar({
    required this.orgId,
    required this.orgName,
    required this.colorStart,
  });

  @override
  State<_ContactBar> createState() => _ContactBarState();
}

class _ContactBarState extends State<_ContactBar> {
  bool _loading = false;

  String get _abbr {
    final words = widget.orgName.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return widget.orgName
        .substring(0, widget.orgName.length.clamp(0, 2))
        .toUpperCase();
  }

  Future<void> _contact() async {
    if (_loading) return;
    setState(() => _loading = true);
    String? conversationId;
    try {
      final convo = await ApiService.createConversation(widget.orgId);
      conversationId = convo['id']?.toString();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).push(
      slideRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          name: widget.orgName.isNotEmpty ? widget.orgName : 'Organization',
          initials: _abbr.isNotEmpty ? _abbr : '?',
          avatarColor: widget.colorStart,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
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
                          const Icon(
                            Icons.chat_bubble_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
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

// ─── Data class ───────────────────────────────────────────────────────────────

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
