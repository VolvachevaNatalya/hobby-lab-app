import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_event.dart';
import '../services/api_service.dart';
import '../services/saved_activities.dart';
import '../theme/app_theme.dart';

// Deterministic colour pair keyed by event id hash.
const _palette = [
  (Color(0xFFFF6B35), Color(0xFFEC4899)),
  (Color(0xFF7C3AED), Color(0xFF3B82F6)),
  (Color(0xFF059669), Color(0xFF0EA5E9)),
  (Color(0xFF6366F1), Color(0xFFEC4899)),
  (Color(0xFFFF6B35), Color(0xFF7C3AED)),
];

(Color, Color) eventPalette(String id) =>
    _palette[id.hashCode.abs() % _palette.length];

// ─── EventCard ────────────────────────────────────────────────────────────────

class EventCard extends StatefulWidget {
  final AppEvent event;
  final VoidCallback onTap;
  /// Provide this to override the default toggle-save behaviour (e.g. Saved screen).
  final Future<void> Function()? onUnsave;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onUnsave,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isSaved = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _isSaved = isEventSaved(widget.event.id);
    savedEventIds.addListener(_onSavedChanged);
  }

  void _onSavedChanged() {
    if (mounted) setState(() => _isSaved = isEventSaved(widget.event.id));
  }

  @override
  void dispose() {
    savedEventIds.removeListener(_onSavedChanged);
    super.dispose();
  }

  Future<void> _toggleSave() async {
    if (_toggling) return;
    _toggling = true;
    try {
      if (_isSaved) {
        if (widget.onUnsave != null) {
          await widget.onUnsave!();
        } else {
          final favId = eventFavoriteIds[widget.event.id];
          removeSavedEvent(widget.event.id);
          if (favId != null) {
            try {
              await ApiService.removeFavorite(favId);
            } catch (_) {
              addSavedEvent(widget.event, favId); // rollback on error
            }
          }
        }
      } else {
        try {
          final fav = await ApiService.addEventFavorite(widget.event.id);
          addSavedEvent(widget.event, fav.id);
        } catch (_) {}
      }
    } finally {
      _toggling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final colors = eventPalette(event.id);
    final dateStr = _fmtDate(event.startDatetime);
    const String? categoryLabel = null;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 94,
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
        child: Stack(
          children: [
            // ── Row: image + content ───────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 94,
                    height: 94,
                    child: _EventImage(
                      imageUrl: null,
                      colorStart: colors.$1,
                      colorEnd: colors.$2,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      // Right padding is wide to leave room for the heart btn.
                      padding: const EdgeInsets.fromLTRB(12, 8, 44, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Category pill
                          if (categoryLabel != null)
                            _CategoryPill(
                                label: categoryLabel, color: colors.$1),

                          // Title
                          Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          // Rating + date
                          _BottomRow(
                            rating: 0,
                            dateStr: dateStr,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Heart button overlay ───────────────────────────────
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _toggleSave,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _isSaved
                        ? const Color(0xFFEC4899).withValues(alpha: 0.15)
                        : AppColors.background.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 16,
                    color: _isSaved
                        ? const Color(0xFFEC4899)
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _fmtDate(String? iso) {
    if (iso == null) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}

// ─── Image / placeholder ──────────────────────────────────────────────────────

class _EventImage extends StatelessWidget {
  final String? imageUrl;
  final Color colorStart;
  final Color colorEnd;

  const _EventImage({
    required this.imageUrl,
    required this.colorStart,
    required this.colorEnd,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
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
          color: Colors.white.withValues(alpha: 0.3),
          size: 40,
        ),
      ),
    );
  }
}

// ─── Category pill ────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Bottom row (rating + date) ───────────────────────────────────────────────

class _BottomRow extends StatelessWidget {
  final double rating;
  final String? dateStr;

  const _BottomRow({required this.rating, this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (rating > 0) ...[
          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFD700)),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (dateStr != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('·',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textMuted)),
            ),
        ],
        if (dateStr != null)
          Expanded(
            child: Text(
              dateStr!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }
}
