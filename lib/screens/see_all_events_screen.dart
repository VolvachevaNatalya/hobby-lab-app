import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/app_event.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'event_details_screen.dart';
import '../routing/transitions.dart';

class SeeAllEventsScreen extends StatefulWidget {
  final String? city;
  const SeeAllEventsScreen({super.key, this.city});

  @override
  State<SeeAllEventsScreen> createState() => _SeeAllEventsScreenState();
}

class _SeeAllEventsScreenState extends State<SeeAllEventsScreen> {
  List<AppEvent> _events = [];
  bool _loading = true;
  String _query = '';
  final _ctrl = TextEditingController();

  static const _styles = [
    (Color(0xFFFF6B35), Color(0xFFEC4899), Icons.wb_sunny_rounded),
    (Color(0xFF7C3AED), Color(0xFF3B82F6), Icons.code_rounded),
    (Color(0xFF059669), Color(0xFF0EA5E9), Icons.weekend_rounded),
  ];

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
      final events = await ApiService.getEvents(city: widget.city);
      if (mounted) setState(() { _events = events; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AppEvent> get _filtered {
    if (_query.isEmpty) return _events;
    final q = _query.toLowerCase();
    return _events.where((e) =>
        e.title.toLowerCase().contains(q) ||
        e.subtitle.toLowerCase().contains(q)).toList();
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
                    child: Text(l10n.eventsSection,
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
                    hintText: l10n.searchActivitiesHint,
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
                                child: const Icon(Icons.event_busy_rounded, color: AppColors.textMuted, size: 32),
                              ),
                              const SizedBox(height: 16),
                              Text(l10n.noActivitiesFound,
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              Text(l10n.tryDifferentFilters,
                                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          itemCount: items.length,
                          itemBuilder: (ctx, i) {
                            final event = items[i];
                            final s = _styles[i % _styles.length];
                            return GestureDetector(
                              onTap: () => Navigator.of(ctx).push(
                                slideRoute(builder: (_) => EventDetailsScreen(
                                  eventId: event.id,
                                  colorStart: s.$1,
                                  colorEnd: s.$2,
                                  icon: s.$3,
                                )),
                              ),
                              child: Container(
                                height: 88,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [s.$1, s.$2], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: s.$1.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 16),
                                    Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                      child: Icon(s.$3, color: Colors.white, size: 26),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(event.badge,
                                              style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1)),
                                          const SizedBox(height: 3),
                                          Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                                          const SizedBox(height: 2),
                                          Text(event.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                                    const SizedBox(width: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
