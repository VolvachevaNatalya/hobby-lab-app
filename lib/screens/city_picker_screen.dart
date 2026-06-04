import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/places_service.dart';
import '../theme/app_theme.dart';

class CityPickerScreen extends StatefulWidget {
  final String? initialCity;
  const CityPickerScreen({super.key, this.initialCity});

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  List<CityResult> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialCity ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() { _results = []; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _fetch(value),
    );
  }

  Future<void> _fetch(String input) async {
    final lang = Localizations.localeOf(context).languageCode;
    final results = await PlacesService.searchCities(input, language: lang);
    if (mounted) setState(() { _results = results; _loading = false; });
  }

  void _onSelect(CityResult city) {
    Navigator.of(context).pop(
      CitySelection(
        name: city.name,
        latitude: city.latitude,
        longitude: city.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasInput = _ctrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                  const SizedBox(width: 14),
                  Text(l10n.searchCity,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Search field ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  onChanged: _onChanged,
                  style: GoogleFonts.poppins(
                      color: AppColors.textPrimary, fontSize: 14),
                  cursorColor: AppColors.purple,
                  decoration: InputDecoration(
                    hintText: l10n.searchCityHint,
                    hintStyle: GoogleFonts.poppins(
                        color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textMuted, size: 20),
                    suffixIcon: hasInput
                        ? GestureDetector(
                            onTap: () {
                              _ctrl.clear();
                              setState(() {
                                _results = [];
                                _loading = false;
                              });
                            },
                            child: const Icon(Icons.close_rounded,
                                color: AppColors.textMuted, size: 18),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.divider),
            // ── Results ───────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : !hasInput
                      ? _buildPrompt(l10n)
                      : _results.isEmpty
                          ? _buildEmpty(l10n)
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _results.length,
                              separatorBuilder: (context, index) => const Divider(
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                                color: AppColors.divider,
                              ),
                              itemBuilder: (ctx, i) => _CityTile(
                                city: _results[i],
                                onTap: () => _onSelect(_results[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrompt(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_city_rounded,
                color: AppColors.purple, size: 30),
          ),
          const SizedBox(height: 14),
          Text(l10n.searchCityHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.search_off_rounded,
                color: AppColors.textMuted, size: 28),
          ),
          const SizedBox(height: 14),
          Text(l10n.noCitySuggestions,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('"${_ctrl.text}"',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  final CityResult city;
  final VoidCallback onTap;

  const _CityTile({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.purple.withValues(alpha: 0.08),
      highlightColor: AppColors.purple.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(city.name,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  if (city.secondaryText.isNotEmpty)
                    Text(city.secondaryText,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
