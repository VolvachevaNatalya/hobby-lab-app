import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import 'activity_details_screen.dart';

// ─── Data ────────────────────────────────────────────────────────────────────

class _Activity {
  final String id;
  final String name;
  final String studio;
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
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.colorStart,
    required this.colorEnd,
    required this.icon,
  });

  bool matches(String q) {
    final lower = q.toLowerCase();
    return name.toLowerCase().contains(lower) ||
        studio.toLowerCase().contains(lower) ||
        category.toLowerCase().contains(lower);
  }
}

// ─── Category display helpers (UI only) ──────────────────────────────────────

IconData _catIcon(String name) => switch (name.toLowerCase()) {
      'art' => Icons.palette_rounded,
      'sport' => Icons.sports_soccer_rounded,
      'music' => Icons.music_note_rounded,
      'education' => Icons.menu_book_rounded,
      'theater' => Icons.theater_comedy_rounded,
      'dance' => Icons.self_improvement_rounded,
      'master class' => Icons.workspace_premium_rounded,
      _ => Icons.category_rounded,
    };

Color _catColor(String name) => switch (name.toLowerCase()) {
      'art' => const Color(0xFFE040FB),
      'sport' => const Color(0xFF4CAF50),
      'music' => const Color(0xFFFF9100),
      'education' => const Color(0xFF40C4FF),
      'theater' => const Color(0xFFFF4081),
      'dance' => const Color(0xFF7C3AED),
      'master class' => const Color(0xFFFFD740),
      _ => const Color(0xFF7C3AED),
    };

// ─── Screen ───────────────────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  final String initialQuery;

  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  bool _showAll = false;
  List<_Activity>? _apiResults;
  bool _searching = false;
  List<String> _catNames = [];
  bool _loadingCats = true;

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
    _loadCategories();
    final initial = widget.initialQuery;
    if (initial.isNotEmpty) {
      if (initial == 'All') {
        _showAll = true;
        _runSearch('');
      } else {
        _query = initial;
        _controller.text = initial;
        _runSearch(initial);
      }
    } else {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _focusNode.requestFocus());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      if (mounted) {
        setState(() {
          _catNames = cats.map((c) => c.name).toList();
          _loadingCats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCats = false);
    }
  }

  Future<void> _runSearch(String q) async {
    setState(() => _searching = true);
    try {
      final classes = await ApiService.searchClasses(q);
      if (!mounted) return;
      setState(() {
        _apiResults = classes.asMap().entries.map((e) {
          final i = e.key;
          final c = _gradients[i % _gradients.length];
          return _Activity(
            id: e.value.id,
            name: e.value.title,
            studio: e.value.organizationName,
            category: e.value.category,
            rating: e.value.averageRating,
            reviewCount: e.value.reviewCount,
            colorStart: c.$1,
            colorEnd: c.$2,
            icon: _icons[i % _icons.length],
          );
        }).toList();
      });
    } catch (_) {
      if (mounted) setState(() => _apiResults = null);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _setQuery(String value) {
    setState(() {
      _query = value;
      _showAll = false;
      _controller.text = value;
      _controller.selection = TextSelection.collapsed(offset: value.length);
    });
    _focusNode.unfocus();
    _runSearch(value);
  }

  void _onTagTap(String tag) {
    if (tag == 'All') {
      setState(() {
        _query = '';
        _showAll = true;
        _controller.clear();
      });
      _focusNode.unfocus();
      _runSearch('');
    } else {
      _setQuery(tag);
    }
  }

  void _clear() {
    setState(() {
      _query = '';
      _showAll = false;
      _apiResults = null;
      _controller.clear();
    });
    _focusNode.requestFocus();
  }

  bool get _showResults => _query.isNotEmpty || _showAll;

  List<_Activity> get _results => _apiResults ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              controller: _controller,
              focusNode: _focusNode,
              hasText: _query.isNotEmpty,
              onChanged: (v) {
                setState(() {
                  _query = v;
                  _showAll = false;
                  if (v.isEmpty) _apiResults = null;
                });
                if (v.isNotEmpty) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 400), () => _runSearch(v));
                }
              },
              onClear: _clear,
            ),
            const Divider(color: AppColors.divider, height: 1),
            Expanded(
              child: _searching
                  ? const Center(child: CircularProgressIndicator())
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      child: _showResults
                          ? _ResultsList(
                              key: const ValueKey('results'),
                              results: _results,
                              query: _query,
                            )
                          : _EmptyState(
                              key: const ValueKey('empty'),
                              activeTag: _query,
                              onTagTap: _onTagTap,
                              categories: _catNames,
                              loadingCategories: _loadingCats,
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _TopBar({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
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
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.purple, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.18),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                cursorColor: AppColors.purple,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchHint,
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.purple,
                    size: 20,
                  ),
                  suffixIcon: hasText
                      ? GestureDetector(
                          onTap: onClear,
                          child: Container(
                            margin: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                              size: 14,
                            ),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String activeTag;
  final ValueChanged<String> onTagTap;
  final List<String> categories;
  final bool loadingCategories;

  const _EmptyState({
    super.key,
    required this.activeTag,
    required this.onTagTap,
    required this.categories,
    this.loadingCategories = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final popularTags = [...categories, 'All'];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(l10n.popularSearches),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: popularTags
                .map((tag) => _PopularChip(
                      label: tag,
                      displayLabel: tag == 'All' ? l10n.allChip : null,
                      isActive: tag == activeTag ||
                          (tag == 'All' && activeTag.isEmpty),
                      onTap: () => onTagTap(tag),
                    ))
                .toList(),
          ),
          const SizedBox(height: 30),
          _SectionLabel(l10n.trendingCategories),
          const SizedBox(height: 16),
          loadingCategories
              ? const SizedBox(
                  height: 96,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SizedBox(
                  height: 96,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, i) => _CategoryCircle(
                      name: categories[i],
                      onTap: () => onTagTap(categories[i]),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.3,
      ),
    );
  }
}

// ─── Popular chip ─────────────────────────────────────────────────────────────

class _PopularChip extends StatelessWidget {
  final String label;
  final String? displayLabel;
  final bool isActive;
  final VoidCallback onTap;

  const _PopularChip({
    required this.label,
    this.displayLabel,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.purple.withValues(alpha: 0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.purple : AppColors.divider,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          displayLabel ?? label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color:
                isActive ? AppColors.purpleLight : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Category circle ──────────────────────────────────────────────────────────

class _CategoryCircle extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;

  const _CategoryCircle({required this.name, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _catColor(name);
    final icon = _catIcon(name);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 18),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 7),
            Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Results list ─────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final List<_Activity> results;
  final String query;

  const _ResultsList({
    super.key,
    required this.results,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
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
                Icons.search_off_rounded,
                color: AppColors.textMuted,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.noResultsFor(query),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.tryDifferentKeywords,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: results.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.brandGradient.createShader(b),
                  child: Text(
                    '${results.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  ' ${AppLocalizations.of(context)!.resultsFound}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }
        return _ResultCard(activity: results[i - 1]);
      },
    );
  }
}

// ─── Result card ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final _Activity activity;
  const _ResultCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ActivityDetailsScreen(
          classId: activity.id.isNotEmpty ? activity.id : null,
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
        height: 112,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          children: [
            // Gradient image
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(17)),
              child: Container(
                width: 112,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [activity.colorStart, activity.colorEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        activity.icon,
                        size: 44,
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          activity.category,
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.studio,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFFFD700)),
                        const SizedBox(width: 3),
                        Text(
                          activity.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${activity.reviewCount})',
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
            ),
            // Bookmark
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_outline_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
