import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/app_city.dart';
import '../models/org_models.dart';
import '../models/app_category.dart';
import '../models/event_recurrence.dart';
import '../routing/transitions.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/recurrence_picker.dart';
import '../widgets/event_scope_dialog.dart';
import 'city_picker_screen.dart';

class OrgEventFormScreen extends StatefulWidget {
  final OrgEvent? event;
  final String? orgId;
  final AppCity? initialCity;
  final bool isDuplicate;
  final VoidCallback? onSaved;

  const OrgEventFormScreen({
    super.key,
    this.event,
    this.orgId,
    this.initialCity,
    this.isDuplicate = false,
    this.onSaved,
  });

  @override
  State<OrgEventFormScreen> createState() => _OrgEventFormScreenState();
}

class _OrgEventFormScreenState extends State<OrgEventFormScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _minAgeCtrl = TextEditingController();
  final _maxAgeCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _priceCommentCtrl = TextEditingController();

  // Keys for scrolling to first error
  final _detailsCardKey = GlobalKey();
  final _dateCardKey = GlobalKey();
  final _locationCardKey = GlobalKey();

  List<AppCategory> _selectedCategories = [];
  List<String> _initialCategoryIds = [];
  String _initialCategoryName = '';
  String? _imageUrl;
  String? _imageLocalPath;
  bool _imageUploading = false;
  DateTime? _date;
  TimeOfDay? _time;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _endDateTimeError = false;
  List<String> _selectedAgeGroups = [];
  bool _ageRangeError = false;
  List<AppCategory> _categories = [];
  bool _loadingCategories = true;
  bool _saving = false;
  bool _isNationwide = false;
  bool _submitted = false;
  AppCity? _selectedCity;
  RecurrenceInput? _recurrence;

  bool get _isEdit => widget.event != null && !widget.isDuplicate;
  bool get _hasCustomAge => _selectedAgeGroups.contains('custom');

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onFieldChanged);
    final e = widget.event;
    if (e != null) {
      _nameCtrl.text = e.name;
      _descCtrl.text = e.description;
      _locationCtrl.text = e.location;
      if (e.ageGroups.isNotEmpty) {
        _selectedAgeGroups = List<String>.from(e.ageGroups);
        if (_selectedAgeGroups.contains('custom')) {
          _minAgeCtrl.text = e.minAge > 0 ? '${e.minAge}' : '';
          _maxAgeCtrl.text = e.maxAge < 99 ? '${e.maxAge}' : '';
        }
      } else if (e.minAge > 0 || e.maxAge < 99) {
        _selectedAgeGroups = ['custom'];
        _minAgeCtrl.text = e.minAge > 0 ? '${e.minAge}' : '';
        _maxAgeCtrl.text = e.maxAge < 99 ? '${e.maxAge}' : '';
      }
      _capacityCtrl.text = e.capacity.toString();
      _priceCtrl.text = e.price > 0 ? e.price.toStringAsFixed(0) : '';
      _priceCommentCtrl.text = e.priceComment ?? '';
      _initialCategoryIds = e.categoryIds;
      _initialCategoryName = e.category;
      _date = e.date;
      _time = e.time;
      if (e.endDateTime != null) {
        _endDate = DateTime(e.endDateTime!.year, e.endDateTime!.month, e.endDateTime!.day);
        _endTime = TimeOfDay(hour: e.endDateTime!.hour, minute: e.endDateTime!.minute);
      }
      _isNationwide = e.isNationwide;
      // Synchronously initialize city so form shows it immediately on open
      if (e.cityId != null) {
        final nameHe = e.cityNameHe ?? '';
        final nameEn = e.cityNameEn ?? '';
        final nameRu = e.cityNameRu ?? '';
        if (nameHe.isNotEmpty || nameEn.isNotEmpty || nameRu.isNotEmpty) {
          _selectedCity = AppCity(
            id: e.cityId!,
            nameHe: nameHe,
            nameEn: nameEn,
            nameRu: nameRu,
          );
        }
      }
      _imageUrl = e.imageUrl;
      final r = e.recurrence;
      if (r != null) {
        _recurrence = RecurrenceInput(
          frequency: r.frequency,
          interval: r.interval,
          endType: r.endType,
          totalCount: r.totalCount,
          endDate: r.endDate,
        );
      }
      if (widget.isDuplicate) {
        _date = null;
        _time = null;
        _endDate = null;
        _endTime = null;
      }
    } else {
      _selectedCity = widget.initialCity;
    }
    _loadCategoriesAndCity();
  }

  Future<void> _loadCategoriesAndCity() async {
    try {
      final cats = await ApiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loadingCategories = false;
          if (widget.event != null && _selectedCategories.isEmpty) {
            if (_initialCategoryIds.isNotEmpty) {
              _selectedCategories = cats
                  .where((c) => _initialCategoryIds.contains(c.id))
                  .toList();
            } else if (_initialCategoryName.isNotEmpty &&
                _initialCategoryName != 'Other') {
              final match = cats
                  .where((c) => c.name == _initialCategoryName)
                  .firstOrNull;
              if (match != null) _selectedCategories = [match];
            }
          }
          final e = widget.event;
          if (e != null && e.cityId != null && _selectedCity == null) {
            final nameHe = e.cityNameHe ?? '';
            final nameEn = e.cityNameEn ?? '';
            final nameRu = e.cityNameRu ?? '';
            if (nameHe.isNotEmpty || nameEn.isNotEmpty || nameRu.isNotEmpty) {
              _selectedCity = AppCity(
                id: e.cityId!,
                nameHe: nameHe,
                nameEn: nameEn,
                nameRu: nameRu,
              );
            }
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  void _onFieldChanged() {
    if (_submitted && mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onFieldChanged);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _minAgeCtrl.dispose();
    _maxAgeCtrl.dispose();
    _capacityCtrl.dispose();
    _priceCtrl.dispose();
    _priceCommentCtrl.dispose();
    super.dispose();
  }

  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final GlobalKey? key;
      if (_nameCtrl.text.trim().isEmpty || _selectedCategories.isEmpty) {
        key = _detailsCardKey;
      } else if (_date == null) {
        key = _dateCardKey;
      } else if (_selectedCity == null && !_isNationwide) {
        key = _locationCardKey;
      } else {
        return;
      }
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    final xfile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xfile == null || !mounted) return;
    setState(() {
      _imageLocalPath = xfile.path;
      _imageUploading = true;
    });
    try {
      final url = await ApiService.uploadFile(xfile.path);
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _imageLocalPath = null;
      });
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.failedToUploadImage, const Color(0xFFEF4444));
      setState(() => _imageLocalPath = null);
    } finally {
      if (mounted) setState(() => _imageUploading = false);
    }
  }

  void _showCategorySheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_loadingCategories) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void toggle(AppCategory cat) {
            final isSelected = _selectedCategories.any((c) => c.id == cat.id);
            if (isSelected) {
              setState(
                () => _selectedCategories.removeWhere((c) => c.id == cat.id),
              );
              setModalState(() {});
            } else {
              if (_selectedCategories.length >= 10) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.maxCategoriesReached,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                return;
              }
              setState(() => _selectedCategories.add(cat));
              setModalState(() {});
            }
          }

          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.selectCategories,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_selectedCategories.length}/10',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.purpleLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.divider),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      shrinkWrap: true,
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final sel = _selectedCategories.any(
                          (c) => c.id == cat.id,
                        );
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => toggle(cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.purple.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: sel
                                        ? LinearGradient(
                                            colors: [
                                              catColorStart(cat.stableNameEn),
                                              catColorEnd(cat.stableNameEn),
                                            ],
                                          )
                                        : null,
                                    color: sel
                                        ? null
                                        : AppColors.surfaceElevated,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    catIcon(cat.stableNameEn),
                                    size: 16,
                                    color: sel
                                        ? Colors.white
                                        : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Builder(builder: (ctx) {
                                    final locale = Localizations.localeOf(ctx).languageCode;
                                    return Text(
                                    cat.localizedName(locale),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: sel
                                          ? AppColors.purpleLight
                                          : AppColors.textPrimary,
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  );
                                  }),
                                ),
                                if (sel)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.purple,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: GestureDetector(
                      onTap: () => Navigator.of(sheetCtx).pop(),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            l10n.btnDone,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) { if (mounted) FocusManager.instance.primaryFocus?.unfocus(); });
  }

  Future<void> _pickDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      locale: const Locale('en'),
      builder: (ctx, child) => Theme(data: darkPickerTheme(ctx), child: child!),
    );
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickEndDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliest = _date != null ? DateTime(_date!.year, _date!.month, _date!.day) : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate != null && !_endDate!.isBefore(earliest) ? _endDate! : earliest,
      firstDate: earliest,
      lastDate: today.add(const Duration(days: 730)),
      locale: const Locale('en'),
      builder: (ctx, child) => Theme(data: darkPickerTheme(ctx), child: child!),
    );
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    if (picked != null && mounted) setState(() {
      _endDate = picked;
      _endDateTimeError = false;
    });
  }

  Future<void> _pickEndTime() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 20, minute: 0),
      builder: (ctx, child) => Theme(data: darkPickerTheme(ctx), child: child!),
    );
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    if (picked != null && mounted) setState(() => _endTime = picked);
  }

  Future<void> _pickTime() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (ctx, child) => Theme(data: darkPickerTheme(ctx), child: child!),
    );
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    if (picked != null && mounted) setState(() => _time = picked);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return; // prevent double-tap
    FocusManager.instance.primaryFocus?.unfocus();

    if (_nameCtrl.text.trim().isEmpty ||
        _selectedCategories.isEmpty ||
        _date == null ||
        (_selectedCity == null && !_isNationwide)) {
      setState(() => _submitted = true);
      _scrollToFirstError();
      return;
    }

    if (_endDate != null) {
      final eventTime = _time ?? const TimeOfDay(hour: 10, minute: 0);
      final startDt = DateTime(_date!.year, _date!.month, _date!.day, eventTime.hour, eventTime.minute);
      final endDt = DateTime(_endDate!.year, _endDate!.month, _endDate!.day,
          _endTime?.hour ?? 23, _endTime?.minute ?? 59);
      if (!endDt.isAfter(startDt)) {
        setState(() => _endDateTimeError = true);
        return;
      }
    }

    // Edit mode: persist to API then return updated event to parent
    if (_isEdit) {
      // Removing recurrence converts this occurrence to standalone and deletes all siblings.
      // No scope dialog needed — the operation has a single unambiguous meaning.
      final removeRecurrence = widget.event!.seriesId != null && _recurrence == null;

      String? scope;
      if (widget.event!.seriesId != null && !removeRecurrence) {
        final title = AppLocalizations.of(context)!.editEventScopeTitle;
        scope = await showEventScopeDialog(context, title: title);
        if (mounted) FocusManager.instance.primaryFocus?.unfocus();
        if (scope == null || !mounted) return;
      }

      setState(() => _saving = true);
      final eventTime = _time ?? const TimeOfDay(hour: 10, minute: 0);
      final startDt = DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        eventTime.hour,
        eventTime.minute,
      );
      String? endDatetimeStr;
      if (_endDate != null) {
        final et = _endTime ?? const TimeOfDay(hour: 23, minute: 59);
        endDatetimeStr = DateTime(
          _endDate!.year, _endDate!.month, _endDate!.day, et.hour, et.minute,
        ).toIso8601String();
      }
      final parsedPrice = double.tryParse(_priceCtrl.text.trim());
      final commentText = _priceCommentCtrl.text.trim();
      final id = int.tryParse(widget.event!.id);
      final catIds = _selectedCategories
          .map((c) => int.tryParse(c.id))
          .whereType<int>()
          .toList();
      if (id != null) {
        try {
          await ApiService.updateEvent(
            id,
            title: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isNotEmpty
                ? _descCtrl.text.trim()
                : null,
            startDatetime: startDt.toIso8601String(),
            endDatetime: endDatetimeStr,
            sendEndDatetime: true,
            categoryIds: catIds.isNotEmpty ? catIds : null,
            ageGroups: _selectedAgeGroups,
            sendAgeGroups: true,
            minAge: _hasCustomAge ? int.tryParse(_minAgeCtrl.text) : null,
            maxAge: _hasCustomAge ? int.tryParse(_maxAgeCtrl.text) : null,
            capacity: int.tryParse(_capacityCtrl.text),
            address: _locationCtrl.text.trim().isNotEmpty
                ? _locationCtrl.text.trim()
                : null,
            cityId: _selectedCity?.id,
            isNationwide: _isNationwide,
            price: parsedPrice,
            priceComment: commentText.isNotEmpty ? commentText : null,
            imageUrl: _imageUrl,
            scope: scope,
            recurrence: scope != 'single' ? _recurrence : null,
            removeRecurrence: removeRecurrence,
          );
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _saving = false);

      // Force parent reload when the event list structure changes:
      // - removing recurrence deletes siblings
      // - adding recurrence to a standalone event generates new occurrence rows
      // - future/series scope edits may affect multiple events
      final convertingToSeries = widget.event!.seriesId == null && _recurrence != null;
      if (convertingToSeries || removeRecurrence || (scope != null && scope != 'single')) {
        widget.onSaved?.call();
        Navigator.of(context).pop(null);
        return;
      }

      final event = OrgEvent(
        id: widget.event!.id,
        name: _nameCtrl.text.trim(),
        category: _selectedCategories.isNotEmpty
            ? _selectedCategories.first.stableNameEn
            : '',
        categoryIds: _selectedCategories.map((c) => c.id).toList(),
        categoryList: _selectedCategories,
        description: _descCtrl.text.trim(),
        date: _date!,
        time: eventTime,
        endDateTime: endDatetimeStr != null ? DateTime.parse(endDatetimeStr) : null,
        location: _locationCtrl.text.trim(),
        cityId: _selectedCity?.id,
        cityNameHe: _selectedCity?.nameHe,
        cityNameEn: _selectedCity?.nameEn,
        cityNameRu: _selectedCity?.nameRu,
        minAge: _hasCustomAge ? int.tryParse(_minAgeCtrl.text) ?? 0 : 0,
        maxAge: _hasCustomAge ? int.tryParse(_maxAgeCtrl.text) ?? 99 : 99,
        ageGroups: List<String>.from(_selectedAgeGroups),
        capacity: int.tryParse(_capacityCtrl.text) ?? 20,
        price: parsedPrice ?? 0,
        priceComment: commentText.isNotEmpty ? commentText : null,
        isNationwide: _isNationwide,
        imageUrl: _imageUrl,
        // Clear series metadata when recurrence was removed for scope=single
        seriesId: removeRecurrence ? null : widget.event!.seriesId,
        occurrenceIndex: removeRecurrence ? null : widget.event!.occurrenceIndex,
        recurrence: removeRecurrence ? null : widget.event!.recurrence,
      );
      widget.onSaved?.call();
      Navigator.of(context).pop(event);
      return;
    }

    // Create mode: save to API
    setState(() => _saving = true);
    try {
      final orgIdInt = int.tryParse(widget.orgId ?? '') ?? 0;
      final eventTime = _time ?? const TimeOfDay(hour: 10, minute: 0);
      final startDt = DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        eventTime.hour,
        eventTime.minute,
      );
      String? createEndDatetimeStr;
      if (_endDate != null) {
        final et = _endTime ?? const TimeOfDay(hour: 23, minute: 59);
        createEndDatetimeStr = DateTime(
          _endDate!.year, _endDate!.month, _endDate!.day, et.hour, et.minute,
        ).toIso8601String();
      }
      final createCatIds = _selectedCategories
          .map((c) => int.tryParse(c.id))
          .whereType<int>()
          .toList();
      await ApiService.createEvent(
        organizationId: orgIdInt,
        title: _nameCtrl.text.trim(),
        startDatetime: startDt.toIso8601String(),
        endDatetime: createEndDatetimeStr,
        categoryIds: createCatIds.isNotEmpty ? createCatIds : null,
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        ageGroups: _selectedAgeGroups.isNotEmpty ? _selectedAgeGroups : null,
        minAge: _hasCustomAge ? int.tryParse(_minAgeCtrl.text) : null,
        maxAge: _hasCustomAge ? int.tryParse(_maxAgeCtrl.text) : null,
        capacity: int.tryParse(_capacityCtrl.text),
        address: _locationCtrl.text.trim().isNotEmpty
            ? _locationCtrl.text.trim()
            : null,
        cityId: _selectedCity?.id,
        isNationwide: _isNationwide,
        price: double.tryParse(_priceCtrl.text.trim()),
        priceComment: _priceCommentCtrl.text.trim().isNotEmpty
            ? _priceCommentCtrl.text.trim()
            : null,
        imageUrl: _imageUrl,
        recurrence: _recurrence,
      );
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.eventCreatedSuccess, const Color(0xFF059669));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        AppLocalizations.of(context)!.failedToCreateEvent,
        const Color(0xFFEF4444),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageUpload(),
                      const SizedBox(height: 24),
                      _sectionLabel(l10n.eventDetailsSection),
                      const SizedBox(height: 12),
                      _buildFieldCard(
                        key: _detailsCardKey,
                        hasError:
                            _submitted &&
                            (_nameCtrl.text.trim().isEmpty ||
                                _selectedCategories.isEmpty),
                        children: [
                          _inlineField(
                            ctrl: _nameCtrl,
                            hint: l10n.eventNameHint,
                            icon: Icons.event_rounded,
                            isRequired: true,
                            error: _submitted && _nameCtrl.text.trim().isEmpty,
                          ),
                          _divider(),
                          _categoryField(
                            isRequired: true,
                            error: _submitted && _selectedCategories.isEmpty,
                          ),
                          _divider(),
                          _buildDescField(),
                        ],
                      ),
                      if (_submitted && _nameCtrl.text.trim().isEmpty)
                        _errorLabel(l10n.fieldRequired),
                      if (_submitted && _selectedCategories.isEmpty)
                        _errorLabel(l10n.fieldRequired),
                      const SizedBox(height: 20),
                      _sectionLabel(l10n.dateTimeSection),
                      const SizedBox(height: 12),
                      _buildFieldCard(
                        key: _dateCardKey,
                        hasError: _submitted && _date == null,
                        children: [
                          _tapField(
                            icon: Icons.calendar_today_rounded,
                            label: _date != null
                                ? fmtDate(_date!)
                                : l10n.selectDate,
                            isEmpty: _date == null,
                            onTap: _pickDate,
                            isRequired: true,
                            error: _submitted && _date == null,
                          ),
                          _divider(),
                          _tapField(
                            icon: Icons.access_time_rounded,
                            label: _time != null
                                ? fmtTime(_time!)
                                : l10n.selectTime,
                            isEmpty: _time == null,
                            onTap: _pickTime,
                          ),
                        ],
                      ),
                      if (_submitted && _date == null)
                        _errorLabel(l10n.fieldRequired),
                      const SizedBox(height: 20),
                      _buildEndDateTimeSection(),
                      const SizedBox(height: 20),
                      _sectionLabel(l10n.locationSection),
                      const SizedBox(height: 12),
                      _buildFieldCard(
                        key: _locationCardKey,
                        hasError:
                            _submitted &&
                            _selectedCity == null &&
                            !_isNationwide,
                        children: [
                          _inlineField(
                            ctrl: _locationCtrl,
                            hint: l10n.addressHint,
                            icon: Icons.location_on_rounded,
                          ),
                          _divider(),
                          _buildCityPickerRow(
                            error:
                                _submitted &&
                                _selectedCity == null &&
                                !_isNationwide,
                          ),
                        ],
                      ),
                      if (_submitted && _selectedCity == null && !_isNationwide)
                        _errorLabel(l10n.fieldRequired),
                      const SizedBox(height: 20),
                      _buildNationwideRow(),
                      const SizedBox(height: 20),
                      _sectionLabel(l10n.repeatSection),
                      const SizedBox(height: 12),
                      _buildRepeatRow(),
                      const SizedBox(height: 20),
                      _sectionLabel(l10n.participantsSection),
                      const SizedBox(height: 12),
                      _buildFieldCard(
                        children: [
                          _ageAudienceField(),
                          _divider(),
                          _inlineField(
                            ctrl: _capacityCtrl,
                            hint: l10n.maxCapacityHint,
                            icon: Icons.group_rounded,
                            type: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          _divider(),
                          _inlineField(
                            ctrl: _priceCtrl,
                            hint: l10n.priceHint,
                            icon: Icons.payments_rounded,
                            type: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                          ),
                          _divider(),
                          _inlineField(
                            ctrl: _priceCommentCtrl,
                            hint: l10n.priceCommentHint,
                            icon: Icons.comment_rounded,
                            action: TextInputAction.done,
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      _buildSaveBtn(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.isDuplicate
                ? AppLocalizations.of(context)!.duplicateEventTitle
                : (_isEdit
                    ? AppLocalizations.of(context)!.editEvent
                    : AppLocalizations.of(context)!.btnNewEvent),
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

  Widget _buildImageUpload() {
    final hasImage = _imageLocalPath != null || _imageUrl != null;
    return GestureDetector(
      onTap: _imageUploading ? null : _pickAndUploadImage,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: _imageUploading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              )
            : hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _imageLocalPath != null
                        ? Image.file(File(_imageLocalPath!), fit: BoxFit.cover)
                        : Image.network(_imageUrl!, fit: BoxFit.cover),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.tapToChange,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppColors.brandGradient.createShader(b),
                      child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.uploadEventImage,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
      letterSpacing: 0.5,
    ),
  );

  Widget _buildFieldCard({
    required List<Widget> children,
    bool hasError = false,
    Key? key,
  }) => Container(
    key: key,
    decoration: BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: hasError ? const Color(0xFFEF4444) : AppColors.divider,
      ),
    ),
    child: Column(children: children),
  );

  Widget _errorLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, top: 4),
    child: Text(
      text,
      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFEF4444)),
    ),
  );

  Widget _divider() => const Divider(
    height: 1,
    thickness: 1,
    color: AppColors.divider,
    indent: 52,
  );

  static const _requiredStyle = TextStyle(
    color: Color(0xFFEF4444),
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  Widget _inlineField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    List<TextInputFormatter>? inputFormatters,
    bool isRequired = false,
    bool error = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: error ? const Color(0xFFEF4444) : AppColors.textMuted,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: type,
              textInputAction: action,
              inputFormatters: inputFormatters,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              cursorColor: AppColors.purple,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (isRequired)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: ctrl,
              builder: (_, val, __) => val.text.trim().isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Text('*', style: _requiredStyle),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _categoryField({bool isRequired = false, bool error = false}) {
    final empty = _selectedCategories.isEmpty;
    final showError = error && empty;
    final locale = Localizations.localeOf(context).languageCode;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showCategorySheet,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                Icons.category_rounded,
                size: 20,
                color: showError
                    ? const Color(0xFFEF4444)
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: empty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppLocalizations.of(context)!.categoriesLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: showError
                              ? const Color(0xFFEF4444)
                              : AppColors.textMuted,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _selectedCategories
                            .map((cat) => _buildCategoryChip(cat, locale))
                            .toList(),
                      ),
                    ),
            ),
            if (isRequired && empty)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: const Text('*', style: _requiredStyle),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(AppCategory cat, String locale) {
    final stable = cat.stableNameEn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            catColorStart(stable).withValues(alpha: 0.25),
            catColorEnd(stable).withValues(alpha: 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: catColorStart(stable).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(catIcon(stable), size: 11, color: catColorStart(stable)),
          const SizedBox(width: 4),
          Text(
            cat.localizedName(locale),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(
              () => _selectedCategories.removeWhere((c) => c.id == cat.id),
            ),
            child: const Icon(
              Icons.close,
              size: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescField() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 17),
            child: Icon(
              Icons.notes_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _descCtrl,
              maxLines: null,
              minLines: 3,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              cursorColor: AppColors.purple,
              decoration: InputDecoration(
                hintText: l10n.descriptionHint,
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tapField({
    required IconData icon,
    required String label,
    required bool isEmpty,
    required VoidCallback onTap,
    bool isRequired = false,
    bool error = false,
    VoidCallback? onClear,
  }) {
    final showError = error && isEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: showError ? const Color(0xFFEF4444) : AppColors.textMuted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: showError
                      ? const Color(0xFFEF4444)
                      : (isEmpty ? AppColors.textMuted : AppColors.textPrimary),
                ),
              ),
            ),
            if (isRequired && isEmpty)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text('*', style: _requiredStyle),
              ),
            if (onClear != null && !isEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8, right: 4),
                  child: Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                ),
              ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ageAudienceField() {
    final l10n = AppLocalizations.of(context)!;
    final String label;
    if (_selectedAgeGroups.isEmpty) {
      label = l10n.ageAudienceLabel;
    } else {
      label = _selectedAgeGroups.map((g) => _ageGroupLabel(g, l10n)).join(', ');
    }
    return _tapField(
      icon: Icons.child_care_rounded,
      label: label,
      isEmpty: _selectedAgeGroups.isEmpty,
      onTap: _showAgeGroupSheet,
      onClear: _selectedAgeGroups.isNotEmpty
          ? () => setState(() {
                _selectedAgeGroups = [];
                _ageRangeError = false;
              })
          : null,
    );
  }

  Widget _ageRangeRow() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.straighten_rounded, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _minAgeCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.poppins(
                color: _ageRangeError ? const Color(0xFFEF4444) : AppColors.textPrimary,
                fontSize: 14,
              ),
              cursorColor: AppColors.purple,
              onChanged: (_) => setState(() => _ageRangeError = false),
              decoration: InputDecoration(
                hintText: l10n.minAgeHint,
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Text(
            ' - ',
            style: GoogleFonts.poppins(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _maxAgeCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.poppins(
                color: _ageRangeError ? const Color(0xFFEF4444) : AppColors.textPrimary,
                fontSize: 14,
              ),
              cursorColor: AppColors.purple,
              onChanged: (_) => setState(() => _ageRangeError = false),
              decoration: InputDecoration(
                hintText: l10n.maxAgeHint,
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ageGroupLabel(String key, AppLocalizations l10n) => switch (key) {
    'toddlers' => l10n.ageGroupToddlers,
    'kids' => l10n.ageGroupKids,
    'teens' => l10n.ageGroupTeens,
    'adults' => l10n.ageGroupAdults,
    'family' => l10n.ageGroupFamily,
    'custom' => l10n.ageGroupCustom,
    _ => key,
  };

  void _showAgeGroupSheet() {
    final l10n = AppLocalizations.of(context)!;
    final groups = ['toddlers', 'kids', 'teens', 'adults', 'family', 'custom'];
    List<String> tempSelected = List<String>.from(_selectedAgeGroups);
    final tempMinCtrl = TextEditingController(text: _minAgeCtrl.text);
    final tempMaxCtrl = TextEditingController(text: _maxAgeCtrl.text);
    bool tempRangeError = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void toggle(String key) {
            setSheetState(() {
              if (key == 'family') {
                if (tempSelected.contains('family')) {
                  tempSelected.remove('family');
                } else {
                  // family is mutually exclusive with all others
                  tempSelected = ['family'];
                  tempMinCtrl.clear();
                  tempMaxCtrl.clear();
                  tempRangeError = false;
                }
              } else {
                tempSelected.remove('family');
                if (tempSelected.contains(key)) {
                  tempSelected.remove(key);
                  if (key == 'custom') {
                    tempMinCtrl.clear();
                    tempMaxCtrl.clear();
                    tempRangeError = false;
                  }
                } else {
                  tempSelected.add(key);
                }
              }
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.ageAudienceLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...groups.map((key) {
                        final selected = tempSelected.contains(key);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => toggle(key),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: selected
                                            ? AppColors.purple
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: selected
                                              ? AppColors.purple
                                              : AppColors.textMuted,
                                          width: 2,
                                        ),
                                      ),
                                      child: selected
                                          ? const Icon(Icons.check_rounded,
                                              size: 14, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      _ageGroupLabel(key, l10n),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (key == 'custom' && selected) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 36, bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: tempMinCtrl,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        style: GoogleFonts.poppins(
                                          color: tempRangeError
                                              ? const Color(0xFFEF4444)
                                              : AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                        cursorColor: AppColors.purple,
                                        onChanged: (_) =>
                                            setSheetState(() => tempRangeError = false),
                                        decoration: InputDecoration(
                                          hintText: l10n.ageFromHint,
                                          hintStyle: GoogleFonts.poppins(
                                            color: AppColors.textMuted,
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '-',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textMuted,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: tempMaxCtrl,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.done,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        style: GoogleFonts.poppins(
                                          color: tempRangeError
                                              ? const Color(0xFFEF4444)
                                              : AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                        cursorColor: AppColors.purple,
                                        onChanged: (_) =>
                                            setSheetState(() => tempRangeError = false),
                                        decoration: InputDecoration(
                                          hintText: l10n.ageToHint,
                                          hintStyle: GoogleFonts.poppins(
                                            color: AppColors.textMuted,
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (tempRangeError)
                                Padding(
                                  padding: const EdgeInsets.only(left: 36, bottom: 8),
                                  child: Text(
                                    l10n.ageCustomRangeError,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        );
                      }),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (tempSelected.contains('custom')) {
                              final minVal = int.tryParse(tempMinCtrl.text);
                              final maxVal = int.tryParse(tempMaxCtrl.text);
                              if (minVal != null && maxVal != null && minVal > maxVal) {
                                setSheetState(() => tempRangeError = true);
                                return;
                              }
                            }
                            _minAgeCtrl.text = tempMinCtrl.text;
                            _maxAgeCtrl.text = tempMaxCtrl.text;
                            setState(() {
                              _selectedAgeGroups = tempSelected;
                              _ageRangeError = false;
                            });
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            l10n.btnSave,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      tempMinCtrl.dispose();
      tempMaxCtrl.dispose();
    });
  }

  Widget _buildEndDateTimeSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            _sectionLabel(l10n.endDateTimeSection),
            const SizedBox(width: 6),
            Text(
              l10n.optionalLabel,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildFieldCard(
          hasError: _endDateTimeError,
          children: [
            _tapField(
              icon: Icons.event_available_rounded,
              label: _endDate != null ? fmtDate(_endDate!) : l10n.endDateLabel,
              isEmpty: _endDate == null,
              onTap: _pickEndDate,
              onClear: _endDate != null
                  ? () => setState(() {
                        _endDate = null;
                        _endTime = null;
                        _endDateTimeError = false;
                      })
                  : null,
            ),
            _divider(),
            _tapField(
              icon: Icons.access_time_rounded,
              label: _endTime != null ? fmtTime(_endTime!) : l10n.endTimeLabel,
              isEmpty: _endTime == null,
              onTap: _endDate != null ? _pickEndTime : () {},
              onClear: _endTime != null ? () => setState(() => _endTime = null) : null,
            ),
          ],
        ),
        if (_endDateTimeError)
          _errorLabel(l10n.endDateTimeValidation),
      ],
    );
  }

  Widget _buildRepeatRow() {
    final l10n = AppLocalizations.of(context)!;
    final label = _recurrence == null
        ? l10n.doesNotRepeat
        : recurrenceInputSummary(_recurrence!, l10n);
    return _buildFieldCard(
      children: [
        _tapField(
          icon: Icons.repeat_rounded,
          label: label,
          isEmpty: _recurrence == null,
          onTap: _openRecurrencePicker,
        ),
      ],
    );
  }

  Future<void> _openRecurrencePicker() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await showRecurrencePicker(
      context,
      current: _recurrence,
      eventDate: _date,
      onClear: () {
        if (mounted) setState(() => _recurrence = null);
      },
      onSelect: (r) {
        if (mounted) setState(() => _recurrence = r);
      },
    );
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
  }

  Widget _buildNationwideRow() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.public_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l10n.showNationwide,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Checkbox(
                    value: _isNationwide,
                    onChanged: (v) =>
                        setState(() => _isNationwide = v ?? false),
                    activeColor: AppColors.purple,
                    side: const BorderSide(
                      color: AppColors.textMuted,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.showNationwideHint,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openCityPicker() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final city = await Navigator.of(
      context,
    ).push<AppCity>(modalRoute(builder: (_) => const CityPickerScreen()));
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    if (city != null && mounted) {
      setState(() => _selectedCity = city);
    }
  }

  Widget _buildCityPickerRow({bool error = false}) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final label = _selectedCity?.displayName(lang);
    final hasLabel = label != null && label.isNotEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openCityPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              Icons.location_city_rounded,
              size: 20,
              color: error ? const Color(0xFFEF4444) : AppColors.textMuted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label != null && label.isNotEmpty ? label : l10n.cityHint,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: error
                      ? const Color(0xFFEF4444)
                      : (hasLabel
                            ? AppColors.textPrimary
                            : AppColors.textMuted),
                ),
              ),
            ),
            if (error && !hasLabel)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text('*', style: _requiredStyle),
              ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveBtn() {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _saving
              ? const LinearGradient(
                  colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
                )
              : AppColors.brandGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _saving
              ? null
              : [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Builder(builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx)!;
                  return Text(
                    _isEdit ? l10n.btnSaveChanges : l10n.createEvent,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  );
                }),
        ),
      ),
    );
  }
}
