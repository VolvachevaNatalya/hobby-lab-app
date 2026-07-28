import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/app_class.dart';
import 'activity_details_screen.dart';
import 'filters_screen.dart';
import '../routing/transitions.dart';

// ─── Category helpers (presentation config only) ──────────────────────────────

Color _catColorStart(String cat) => switch (cat.toLowerCase()) {
      'sport' => const Color(0xFF059669),
      'art' => const Color(0xFFFF6B35),
      'music' => const Color(0xFFEC4899),
      'education' => const Color(0xFF3B82F6),
      'theater' => const Color(0xFF9333EA),
      'dance' => const Color(0xFF7C3AED),
      'master class' => const Color(0xFFFFD700),
      _ => const Color(0xFF7C3AED),
    };

Color _catColorEnd(String cat) => switch (cat.toLowerCase()) {
      'sport' => const Color(0xFF0EA5E9),
      'art' => const Color(0xFFEC4899),
      'music' => const Color(0xFF7C3AED),
      'education' => const Color(0xFF7C3AED),
      'theater' => const Color(0xFFEC4899),
      'dance' => const Color(0xFF3B82F6),
      'master class' => const Color(0xFFFF9100),
      _ => const Color(0xFFEC4899),
    };

IconData _catIcon(String cat) => switch (cat.toLowerCase()) {
      'sport' => Icons.sports_soccer_rounded,
      'art' => Icons.palette_rounded,
      'music' => Icons.music_note_rounded,
      'education' => Icons.school_rounded,
      'theater' => Icons.theater_comedy_rounded,
      'dance' => Icons.self_improvement_rounded,
      'master class' => Icons.star_rounded,
      _ => Icons.category_rounded,
    };

// ─── Screen ───────────────────────────────────────────────────────────────────

class SeeAllScreen extends StatefulWidget {
  final String title;
  final String? initialCategory;
  final int? categoryId;
  final int? cityId;

  const SeeAllScreen({super.key, required this.title, this.initialCategory, this.categoryId, this.cityId});

  @override
  State<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends State<SeeAllScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String? _cat;
  bool _loading = true;
  List<AppClass> _classes = [];
  List<String> _chips = ['All'];

  @override
  void initState() {
    super.initState();
    _cat = widget.initialCategory;
    _loadData();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final classesF = ApiService.getClasses(categoryId: widget.categoryId, cityId: widget.cityId);
      final catsF = ApiService.getCategories();
      final classes = await classesF;
      final cats = await catsF;
      if (mounted) {
        setState(() {
          _classes = classes;
          _chips = ['All', ...cats.map((c) => c.name)];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AppClass> get _filtered {
    var list = _classes;
    if (_cat != null) {
      list = list.where((a) => a.category.toLowerCase() == _cat!.toLowerCase()).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((a) =>
        a.title.toLowerCase().contains(q) ||
        a.organizationName.toLowerCase().contains(q) ||
        a.category.toLowerCase().contains(q),
      ).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, items.length),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            _buildSearchRow(context),
            const SizedBox(height: 12),
            _buildChips(),
            const SizedBox(height: 4),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? _buildEmpty()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 178 / 252,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, i) =>
                              _ActivityCard(cls: items[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
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
            child: Text(
              widget.title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            _loading ? '' : AppLocalizations.of(context)!.countResults(count),
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
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
                style: GoogleFonts.poppins(
                    color: AppColors.textPrimary, fontSize: 13),
                cursorColor: AppColors.purple,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchActivitiesHint,
                  hintStyle: GoogleFonts.poppins(
                      color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textMuted, size: 18),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() {
                            _query = '';
                            _ctrl.clear();
                          }),
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textMuted, size: 16),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              modalRoute(builder: (_) => const FiltersScreen()),
            ),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.tune_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _chips.length,
        itemBuilder: (_, i) {
          final c = _chips[i];
          final active = c == 'All' ? _cat == null : _cat == c;
          return GestureDetector(
            onTap: () => setState(() => _cat = c == 'All' ? null : c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.purple.withValues(alpha: 0.15)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.purple : AppColors.divider,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  c == 'All' ? AppLocalizations.of(context)!.allChip : c,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                    color: active
                        ? AppColors.purpleLight
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.search_off_rounded,
                color: AppColors.textMuted, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noActivitiesFound,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.tryDifferentFilters,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Activity card (grid) ─────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final AppClass cls;
  const _ActivityCard({required this.cls});

  @override
  Widget build(BuildContext context) {
    final cs = _catColorStart(cls.category);
    final ce = _catColorEnd(cls.category);
    final icon = _catIcon(cls.category);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        slideRoute(builder: (_) => ActivityDetailsScreen(
          classId: cls.id,
          name: cls.title,
          studio: cls.organizationName,
          category: cls.category,
          rating: cls.averageRating,
          reviewCount: cls.reviewCount,
          colorStart: cs,
          colorEnd: ce,
          heroIcon: icon,
        )),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
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
                      colors: [cs, ce],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        right: -14,
                        bottom: -14,
                        child: Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(icon,
                            size: 42,
                            color: Colors.white.withValues(alpha: 0.35)),
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
                            cls.category,
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
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bookmark_outline_rounded,
                              color: Colors.white, size: 14),
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
                      cls.title,
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
                        const Icon(Icons.storefront_rounded,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            cls.organizationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFFFD700)),
                        const SizedBox(width: 3),
                        Text(
                          cls.averageRating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '(${cls.reviewCount})',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: AppColors.textMuted),
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
