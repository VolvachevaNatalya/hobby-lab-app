import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../routing/transitions.dart';
import 'event_details_screen.dart';

class EventScheduleScreen extends StatefulWidget {
  final int seriesId;
  final int? organizationId;
  final Color colorStart;
  final Color colorEnd;
  final bool includePast;

  const EventScheduleScreen({
    super.key,
    required this.seriesId,
    this.organizationId,
    this.colorStart = const Color(0xFF7C3AED),
    this.colorEnd = const Color(0xFFEC4899),
    this.includePast = false,
  });

  @override
  State<EventScheduleScreen> createState() => _EventScheduleScreenState();
}

class _EventScheduleScreenState extends State<EventScheduleScreen> {
  List<Map<String, dynamic>> _occurrences = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getSeriesOccurrences(
        widget.seriesId,
        organizationId: widget.organizationId,
        includePast: widget.includePast,
      );
      if (!mounted) return;
      data.sort((a, b) {
        final da = a['start_datetime']?.toString() ?? '';
        final db = b['start_datetime']?.toString() ?? '';
        return da.compareTo(db);
      });
      setState(() => _occurrences = data);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load schedule');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(l10n),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.scheduleTitle,
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

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.purple),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMuted),
        ),
      );
    }
    if (_occurrences.isEmpty) {
      return Center(
        child: Text(
          widget.includePast ? l10n.noOccurrences : l10n.noUpcomingOccurrences,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: _occurrences.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _OccurrenceRow(
        occurrence: _occurrences[i],
        colorStart: widget.colorStart,
        colorEnd: widget.colorEnd,
        isPast: _isPast(_occurrences[i]),
        onTap: () => Navigator.of(context).push(
          slideRoute(
            builder: (_) => EventDetailsScreen(
              eventId: _occurrences[i]['id'].toString(),
              colorStart: widget.colorStart,
              colorEnd: widget.colorEnd,
            ),
          ),
        ),
      ),
    );
  }

  bool _isPast(Map<String, dynamic> e) {
    final raw = e['end_datetime']?.toString() ?? e['start_datetime']?.toString();
    if (raw == null) return false;
    final dt = DateTime.tryParse(raw);
    return dt != null && dt.isBefore(DateTime.now());
  }
}

// ─── Occurrence row ───────────────────────────────────────────────────────────

class _OccurrenceRow extends StatelessWidget {
  final Map<String, dynamic> occurrence;
  final Color colorStart;
  final Color colorEnd;
  final bool isPast;
  final VoidCallback onTap;

  const _OccurrenceRow({
    required this.occurrence,
    required this.colorStart,
    required this.colorEnd,
    required this.isPast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final start = _parseUtc(occurrence['start_datetime']?.toString());
    final end = _parseUtc(occurrence['end_datetime']?.toString());
    final textColor = isPast ? AppColors.textMuted : AppColors.textPrimary;
    final subtextColor = isPast ? AppColors.textMuted : AppColors.textSecondary;
    final iconColor = isPast
        ? AppColors.textMuted
        : colorStart;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: isPast
                    ? AppColors.surfaceElevated
                    : colorStart.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: isPast ? Border.all(color: AppColors.divider) : null,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (start != null)
                    Text(
                      _fmtDate(start),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  if (start != null)
                    Text(
                      _fmtTimeRange(start, end),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isPast ? AppColors.textMuted : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseUtc(String? raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _fmtDate(DateTime dt) {
    const months = [
      '',
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtTimeRange(DateTime start, DateTime? end) {
    if (end == null) return _fmtTime(start);
    return '${_fmtTime(start)} – ${_fmtTime(end)}';
  }
}
