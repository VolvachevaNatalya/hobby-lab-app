import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/org_models.dart';
import '../models/app_category.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class OrgEventFormScreen extends StatefulWidget {
  final OrgEvent? event;
  final String? orgId;

  const OrgEventFormScreen({super.key, this.event, this.orgId});

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

  String _category = '';
  String _categoryId = '';
  DateTime? _date;
  TimeOfDay? _time;
  List<AppCategory> _categories = [];
  bool _loadingCategories = true;
  bool _saving = false;
  bool _isNationwide = false;
  bool _submitted = false;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onFieldChanged);
    final e = widget.event;
    if (e != null) {
      _nameCtrl.text = e.name;
      _descCtrl.text = e.description;
      _locationCtrl.text = e.location;
      _minAgeCtrl.text = e.minAge > 0 ? '${e.minAge}' : '';
      _maxAgeCtrl.text = e.maxAge < 99 ? '${e.maxAge}' : '';
      _capacityCtrl.text = e.capacity.toString();
      _priceCtrl.text = e.price > 0 ? e.price.toStringAsFixed(0) : '';
      _priceCommentCtrl.text = e.priceComment ?? '';
      _category = e.category;
      _date = e.date;
      _time = e.time;
      _isNationwide = e.isNationwide;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loadingCategories = false;
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
      if (_nameCtrl.text.trim().isEmpty || _category.isEmpty) {
        key = _detailsCardKey;
      } else if (_date == null) {
        key = _dateCardKey;
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

  void _showCategorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Category',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              if (_loadingCategories)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ..._categories.map((cat) {
                  final sel = _category == cat.name;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _category = cat.name;
                        _categoryId = cat.id;
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
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
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              gradient: sel
                                  ? LinearGradient(colors: [
                                      catColorStart(cat.name),
                                      catColorEnd(cat.name)
                                    ])
                                  : null,
                              color: sel ? null : AppColors.surfaceElevated,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(catIcon(cat.name),
                                size: 16,
                                color: sel ? Colors.white : AppColors.textMuted),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(cat.name,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: sel
                                        ? AppColors.purpleLight
                                        : AppColors.textPrimary,
                                    fontWeight: sel
                                        ? FontWeight.w600
                                        : FontWeight.w400)),
                          ),
                          if (sel)
                            const Icon(Icons.check_rounded,
                                color: AppColors.purple, size: 18),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('en'),
      builder: (ctx, child) =>
          Theme(data: darkPickerTheme(ctx), child: child!),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (ctx, child) =>
          Theme(data: darkPickerTheme(ctx), child: child!),
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _save() async {
    if (_saving) return; // prevent double-tap

    if (_nameCtrl.text.trim().isEmpty || _category.isEmpty || _date == null) {
      setState(() => _submitted = true);
      _scrollToFirstError();
      return;
    }

    // Edit mode: persist to API then return updated event to parent
    if (_isEdit) {
      setState(() => _saving = true);
      final eventTime = _time ?? const TimeOfDay(hour: 10, minute: 0);
      final startDt = DateTime(
        _date!.year, _date!.month, _date!.day,
        eventTime.hour, eventTime.minute,
      );
      final parsedPrice = double.tryParse(_priceCtrl.text.trim());
      final commentText = _priceCommentCtrl.text.trim();
      final id = int.tryParse(widget.event!.id);
      if (id != null) {
        try {
          await ApiService.updateEvent(
            id,
            title: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
            startDatetime: startDt.toIso8601String(),
            minAge: int.tryParse(_minAgeCtrl.text),
            maxAge: int.tryParse(_maxAgeCtrl.text),
            capacity: int.tryParse(_capacityCtrl.text),
            address: _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
            isNationwide: _isNationwide,
            price: parsedPrice,
            priceComment: commentText.isNotEmpty ? commentText : null,
          );
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _saving = false);
      final event = OrgEvent(
        id: widget.event!.id,
        name: _nameCtrl.text.trim(),
        category: _category,
        description: _descCtrl.text.trim(),
        date: _date!,
        time: eventTime,
        location: _locationCtrl.text.trim(),
        minAge: int.tryParse(_minAgeCtrl.text) ?? 0,
        maxAge: int.tryParse(_maxAgeCtrl.text) ?? 99,
        capacity: int.tryParse(_capacityCtrl.text) ?? 20,
        price: parsedPrice ?? 0,
        priceComment: commentText.isNotEmpty ? commentText : null,
        isNationwide: _isNationwide,
      );
      Navigator.of(context).pop(event);
      return;
    }

    // Create mode: save to API
    setState(() => _saving = true);
    try {
      final orgIdInt = int.tryParse(widget.orgId ?? '') ?? 0;
      final eventTime = _time ?? const TimeOfDay(hour: 10, minute: 0);
      final startDt = DateTime(
        _date!.year, _date!.month, _date!.day,
        eventTime.hour, eventTime.minute,
      );
      await ApiService.createEvent(
        organizationId: orgIdInt,
        title: _nameCtrl.text.trim(),
        startDatetime: startDt.toIso8601String(),
        categoryId: _categoryId.isNotEmpty ? int.tryParse(_categoryId) : null,
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        minAge: int.tryParse(_minAgeCtrl.text),
        maxAge: int.tryParse(_maxAgeCtrl.text),
        capacity: int.tryParse(_capacityCtrl.text),
        address: _locationCtrl.text.trim().isNotEmpty
            ? _locationCtrl.text.trim()
            : null,
        isNationwide: _isNationwide,
        price: double.tryParse(_priceCtrl.text.trim()),
        priceComment: _priceCommentCtrl.text.trim().isNotEmpty
            ? _priceCommentCtrl.text.trim()
            : null,
      );
      if (!mounted) return;
      _showSnack('Event created successfully', const Color(0xFF059669));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to create event. Please try again.',
          const Color(0xFFEF4444));
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
        onTap: () => FocusScope.of(context).unfocus(),
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
                    _sectionLabel('Event Details'),
                    const SizedBox(height: 12),
                    _buildFieldCard(
                      key: _detailsCardKey,
                      hasError: _submitted &&
                          (_nameCtrl.text.trim().isEmpty ||
                              _category.isEmpty),
                      children: [
                        _inlineField(
                          ctrl: _nameCtrl,
                          hint: 'Event name',
                          icon: Icons.event_rounded,
                          isRequired: true,
                          error: _submitted && _nameCtrl.text.trim().isEmpty,
                        ),
                        _divider(),
                        _categoryField(
                          isRequired: true,
                          error: _submitted && _category.isEmpty,
                        ),
                        _divider(),
                        _buildDescField(),
                      ],
                    ),
                    if (_submitted && _nameCtrl.text.trim().isEmpty)
                      _errorLabel(l10n.fieldRequired),
                    if (_submitted && _category.isEmpty)
                      _errorLabel(l10n.fieldRequired),
                    const SizedBox(height: 20),
                    _sectionLabel('Date & Time'),
                    const SizedBox(height: 12),
                    _buildFieldCard(
                      key: _dateCardKey,
                      hasError: _submitted && _date == null,
                      children: [
                        _tapField(
                          icon: Icons.calendar_today_rounded,
                          label: _date != null ? fmtDate(_date!) : 'Select date',
                          isEmpty: _date == null,
                          onTap: _pickDate,
                          isRequired: true,
                          error: _submitted && _date == null,
                        ),
                        _divider(),
                        _tapField(
                          icon: Icons.access_time_rounded,
                          label: _time != null ? fmtTime(_time!) : 'Select time',
                          isEmpty: _time == null,
                          onTap: _pickTime,
                        ),
                      ],
                    ),
                    if (_submitted && _date == null)
                      _errorLabel(l10n.fieldRequired),
                    const SizedBox(height: 20),
                    _sectionLabel('Location'),
                    const SizedBox(height: 12),
                    _buildFieldCard(children: [
                      _inlineField(
                        ctrl: _locationCtrl,
                        hint: 'Address / venue name',
                        icon: Icons.location_on_rounded,
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildNationwideRow(),
                    const SizedBox(height: 20),
                    _sectionLabel('Participants'),
                    const SizedBox(height: 12),
                    _buildFieldCard(children: [
                      _ageRangeRow(),
                      _divider(),
                      _inlineField(
                        ctrl: _capacityCtrl,
                        hint: 'Max capacity',
                        icon: Icons.group_rounded,
                        type: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      _divider(),
                      _inlineField(
                        ctrl: _priceCtrl,
                        hint: 'Price (₪) — leave blank if free',
                        icon: Icons.payments_rounded,
                        type: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                      ),
                      _divider(),
                      _inlineField(
                        ctrl: _priceCommentCtrl,
                        hint: 'Price comment (optional)',
                        icon: Icons.comment_rounded,
                        action: TextInputAction.done,
                      ),
                    ]),
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
          Text(
            _isEdit ? 'Edit Event' : 'New Event',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUpload() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.purple.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                child: const Icon(Icons.add_photo_alternate_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 8),
              Text('Upload Event Image',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textMuted, letterSpacing: 0.5));

  Widget _buildFieldCard({
    required List<Widget> children,
    bool hasError = false,
    Key? key,
  }) =>
      Container(
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
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 11, color: const Color(0xFFEF4444))),
      );

  Widget _divider() => const Divider(
      height: 1, thickness: 1, color: AppColors.divider, indent: 52);

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
          Icon(icon, size: 20,
              color: error ? const Color(0xFFEF4444) : AppColors.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: type,
              textInputAction: action,
              inputFormatters: inputFormatters,
              style: GoogleFonts.poppins(
                  color: AppColors.textPrimary, fontSize: 14),
              cursorColor: AppColors.purple,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                    color: AppColors.textMuted, fontSize: 14),
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
    final empty = _category.isEmpty;
    final showError = error && empty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showCategorySheet,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.category_rounded,
                size: 20,
                color: showError
                    ? const Color(0xFFEF4444)
                    : AppColors.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                empty ? 'Category' : _category,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: showError
                      ? const Color(0xFFEF4444)
                      : (empty ? AppColors.textMuted : AppColors.textPrimary),
                ),
              ),
            ),
            if (isRequired && empty)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text('*', style: _requiredStyle),
              ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDescField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 17),
            child: Icon(Icons.notes_rounded,
                size: 20, color: AppColors.textMuted),
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
                  color: AppColors.textPrimary, fontSize: 14),
              cursorColor: AppColors.purple,
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: GoogleFonts.poppins(
                    color: AppColors.textMuted, fontSize: 14),
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
  }) {
    final showError = error && isEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: showError
                    ? const Color(0xFFEF4444)
                    : AppColors.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: showError
                      ? const Color(0xFFEF4444)
                      : (isEmpty
                          ? AppColors.textMuted
                          : AppColors.textPrimary),
                ),
              ),
            ),
            if (isRequired && isEmpty)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text('*', style: _requiredStyle),
              ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _ageRangeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.child_care_rounded, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _minAgeCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.poppins(
                  color: AppColors.textPrimary, fontSize: 14),
              cursorColor: AppColors.purple,
              decoration: InputDecoration(
                hintText: 'Min age',
                hintStyle: GoogleFonts.poppins(
                    color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Text(' — ',
              style: GoogleFonts.poppins(
                  color: AppColors.textMuted, fontSize: 14)),
          Expanded(
            child: TextField(
              controller: _maxAgeCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.poppins(
                  color: AppColors.textPrimary, fontSize: 14),
              cursorColor: AppColors.purple,
              decoration: InputDecoration(
                hintText: 'Max age',
                hintStyle: GoogleFonts.poppins(
                    color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNationwideRow() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldCard(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.public_rounded,
                    size: 20, color: AppColors.textMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(l10n.showNationwide,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: AppColors.textPrimary)),
                ),
                Checkbox(
                  value: _isNationwide,
                  onChanged: (v) =>
                      setState(() => _isNationwide = v ?? false),
                  activeColor: AppColors.purple,
                  side: const BorderSide(
                      color: AppColors.textMuted, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(l10n.showNationwideHint,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textMuted)),
        ),
      ],
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
              ? const LinearGradient(colors: [
                  Color(0xFF9CA3AF),
                  Color(0xFF6B7280),
                ])
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
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  _isEdit ? 'Save Changes' : 'Create Event',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
        ),
      ),
    );
  }
}
