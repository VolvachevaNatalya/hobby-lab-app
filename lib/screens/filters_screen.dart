import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/app_category.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

const _dayKeys = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  RangeValues _age = const RangeValues(3, 120);
  RangeValues _price = const RangeValues(0, 500);
  double _distance = 10;
  final Set<String> _selectedCatIds = {};
  final Set<String> _selectedDays = {};
  List<AppCategory> _cats = [];
  bool _loadingCats = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      if (mounted) {
        setState(() {
          _cats = cats;
          _loadingCats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCats = false);
    }
  }

  void _reset() => setState(() {
        _age = const RangeValues(3, 120);
        _price = const RangeValues(0, 500);
        _distance = 10;
        _selectedCatIds.clear();
        _selectedDays.clear();
      });

  int get _activeCount =>
      (_age != const RangeValues(3, 120) ? 1 : 0) +
      (_price != const RangeValues(0, 500) ? 1 : 0) +
      (_distance != 10 ? 1 : 0) +
      _selectedCatIds.length +
      _selectedDays.length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localDays = [
      l10n.daySunAbbrev,
      l10n.dayMonAbbrev,
      l10n.dayTueAbbrev,
      l10n.dayWedAbbrev,
      l10n.dayThuAbbrev,
      l10n.dayFriAbbrev,
      l10n.daySatAbbrev,
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Age range
                    _buildSectionLabel(l10n.ageRangeSection),
                    const SizedBox(height: 6),
                    _buildRangeDisplay(
                      '${_age.start.round()} ${l10n.ageSuffix}',
                      '${_age.end.round()} ${l10n.ageSuffix}',
                    ),
                    _buildRangeSlider(
                      values: _age,
                      min: 3,
                      max: 120,
                      divisions: 117,
                      onChanged: (v) => setState(() => _age = v),
                    ),
                    const SizedBox(height: 24),
                    // Price range
                    _buildSectionLabel(l10n.filterPriceRange),
                    const SizedBox(height: 6),
                    _buildRangeDisplay(
                      _price.start == 0
                          ? l10n.eventFree
                          : '₪${_price.start.round()}',
                      '₪${_price.end.round()}',
                    ),
                    _buildRangeSlider(
                      values: _price,
                      min: 0,
                      max: 500,
                      divisions: 50,
                      onChanged: (v) => setState(() => _price = v),
                    ),
                    const SizedBox(height: 24),
                    // Categories
                    _buildSectionLabel(l10n.filterCategory),
                    const SizedBox(height: 12),
                    _loadingCats
                        ? const SizedBox(
                            height: 40,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : Builder(builder: (context) {
                            final locale = Localizations.localeOf(context).languageCode;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _cats
                                  .map((c) => _ToggleChip(
                                        label: c.localizedName(locale),
                                        selected: _selectedCatIds.contains(c.id),
                                        onTap: () => setState(() {
                                          if (_selectedCatIds.contains(c.id)) {
                                            _selectedCatIds.remove(c.id);
                                          } else {
                                            _selectedCatIds.add(c.id);
                                          }
                                        }),
                                      ))
                                  .toList(),
                            );
                          }),
                    const SizedBox(height: 24),
                    // Day of week
                    _buildSectionLabel(l10n.dayOfWeekLabel),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(_dayKeys.length, (i) {
                        final key = _dayKeys[i];
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2),
                            child: _DayChip(
                              label: localDays[i],
                              selected: _selectedDays.contains(key),
                              onTap: () => setState(() {
                                if (_selectedDays.contains(key)) {
                                  _selectedDays.remove(key);
                                } else {
                                  _selectedDays.add(key);
                                }
                              }),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    // Distance
                    _buildSectionLabel(l10n.filterDistance),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          l10n.upToKm(_distance.round()),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          l10n.maxKmLabel,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.purple,
                        inactiveTrackColor: AppColors.divider,
                        thumbColor: AppColors.purple,
                        overlayColor:
                            AppColors.purple.withValues(alpha: 0.12),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        value: _distance,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        onChanged: (v) => setState(() => _distance = v),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
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
              l10n.filtersTitle,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (_activeCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_activeCount',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          GestureDetector(
            onTap: _reset,
            child: Text(
              l10n.btnReset,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );

  Widget _buildRangeDisplay(String start, String end) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          _ValueBadge(text: start),
          Expanded(
            child: Center(
              child: Container(
                height: 1,
                color: AppColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          _ValueBadge(text: end),
        ],
      ),
    );
  }

  Widget _buildRangeSlider({
    required RangeValues values,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.purple,
        inactiveTrackColor: AppColors.divider,
        thumbColor: AppColors.purple,
        overlayColor: AppColors.purple.withValues(alpha: 0.12),
        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
        trackHeight: 4,
      ),
      child: RangeSlider(
        values: values,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border:
            Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.btnShowResults,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ValueBadge extends StatelessWidget {
  final String text;
  const _ValueBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.purpleLight,
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple.withValues(alpha: 0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.purple : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? AppColors.purpleLight
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple.withValues(alpha: 0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.purple : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w400,
              color: selected
                  ? AppColors.purpleLight
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
