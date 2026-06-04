import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_event.dart';
import '../services/api_service.dart';
import '../services/saved_activities.dart';

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
      if (mounted) setState(() => _event = event);
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
            if (_event != null) addSavedEvent(_event!, favId); // rollback
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
          ? const Center(child: CircularProgressIndicator())
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
                    fontSize: 14, color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final event = _event!;
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(event),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCards(event),
                    if (event.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'About',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        event.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.65,
                        ),
                      ),
                    ],
                    if (event.minAge != null || event.maxAge != null || event.capacity != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Details',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDetailsChips(event),
                    ],
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildTopBar(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(AppEvent event) {
    return Container(
      height: 220,
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
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: Colors.white, size: 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _toggleSave,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _isSaved
                  ? const Color(0xFFEC4899).withValues(alpha: 0.85)
                  : Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards(AppEvent event) {
    final items = <_InfoItem>[];

    if (event.startDatetime != null) {
      final dt = DateTime.tryParse(event.startDatetime!);
      if (dt != null) {
        items.add(_InfoItem(
          icon: Icons.calendar_today_rounded,
          label: 'Date',
          value: _fmtDate(dt),
          color: const Color(0xFF0EA5E9),
        ));
        items.add(_InfoItem(
          icon: Icons.access_time_rounded,
          label: 'Time',
          value: _fmtTime(dt),
          color: const Color(0xFF7C3AED),
        ));
      }
    }

    final hasAddress = event.address != null && event.address!.isNotEmpty;
    final hasCity = event.city != null && event.city!.isNotEmpty;
    if (hasAddress || hasCity) {
      final loc = [event.address, event.city]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');
      items.add(_InfoItem(
        icon: Icons.location_on_rounded,
        label: 'Location',
        value: loc,
        color: const Color(0xFFEC4899),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: items
          .map((item) => Container(
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
              ))
          .toList(),
    );
  }

  Widget _buildDetailsChips(AppEvent event) {
    final chips = <Widget>[];
    if (event.minAge != null && event.maxAge != null) {
      chips.add(_chip(
        'Ages ${event.minAge}–${event.maxAge}',
        AppColors.purple.withValues(alpha: 0.12),
        AppColors.purpleLight,
      ));
    }
    if (event.capacity != null) {
      chips.add(_chip(
        '${event.capacity} spots',
        const Color(0xFF059669).withValues(alpha: 0.12),
        const Color(0xFF059669),
      ));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

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
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

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
