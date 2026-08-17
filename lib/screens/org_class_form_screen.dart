import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/org_models.dart';
import '../models/app_category.dart';
import '../services/api_service.dart';
import 'org_group_form_screen.dart';
import '../routing/transitions.dart';

class OrgClassFormScreen extends StatefulWidget {
  final OrgClass? orgClass;
  final String? orgId;

  const OrgClassFormScreen({super.key, this.orgClass, this.orgId});

  @override
  State<OrgClassFormScreen> createState() => _OrgClassFormScreenState();
}

class _OrgClassFormScreenState extends State<OrgClassFormScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _detailsCardKey = GlobalKey();

  final List<AppCategory> _selectedCategories = [];
  String? _imageUrl;
  String? _imageLocalPath;
  bool _imageUploading = false;
  List<OrgGroup> _groups = [];
  List<AppCategory> _categories = [];
  bool _loadingCategories = true;
  bool _saving = false;
  bool _submitted = false;

  bool get _isEdit => widget.orgClass != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onFieldChanged);
    final c = widget.orgClass;
    if (c != null) {
      _nameCtrl.text = c.name;
      _descCtrl.text = c.description;
      _groups = List.from(c.groups);
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
          if (_isEdit && _selectedCategories.isEmpty) {
            final orgClass = widget.orgClass!;
            if (orgClass.categoryIds.isNotEmpty) {
              for (final id in orgClass.categoryIds) {
                final match = cats.where((c) => c.id == id);
                if (match.isNotEmpty) _selectedCategories.add(match.first);
              }
            } else if (orgClass.category.isNotEmpty) {
              final match = cats.where(
                (c) => c.name.toLowerCase() == orgClass.category.toLowerCase(),
              );
              if (match.isNotEmpty) _selectedCategories.add(match.first);
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
    super.dispose();
  }

  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_detailsCardKey.currentContext != null) {
        Scrollable.ensureVisible(
          _detailsCardKey.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCategorySheet() {
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
              setState(() => _selectedCategories.removeWhere((c) => c.id == cat.id));
              setModalState(() {});
            } else {
              if (_selectedCategories.length >= 10) {
                messenger.showSnackBar(SnackBar(
                  content: Text(l10n.maxCategoriesReached,
                      style: GoogleFonts.poppins(fontSize: 13)),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ));
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
                            width: 40, height: 4,
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
                                    color: AppColors.textPrimary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_selectedCategories.length}/10',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.purpleLight),
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
                        final sel =
                            _selectedCategories.any((c) => c.id == cat.id);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => toggle(cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
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
                                            catColorStart(cat.stableNameEn),
                                            catColorEnd(cat.stableNameEn),
                                          ])
                                        : null,
                                    color: sel
                                        ? null
                                        : AppColors.surfaceElevated,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(catIcon(cat.stableNameEn),
                                      size: 16,
                                      color: sel
                                          ? Colors.white
                                          : AppColors.textMuted),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Builder(builder: (ctx) {
                                    final locale = Localizations.localeOf(ctx).languageCode;
                                    return Text(cat.localizedName(locale),
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: sel
                                                ? AppColors.purpleLight
                                                : AppColors.textPrimary,
                                            fontWeight: sel
                                                ? FontWeight.w600
                                                : FontWeight.w400));
                                  }),
                                ),
                                if (sel)
                                  const Icon(Icons.check_rounded,
                                      color: AppColors.purple, size: 18),
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
                          child: Text(l10n.btnDone,
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
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
    );
  }

  Future<void> _pickAndUploadImage() async {
    final xfile = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 85);
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

  Future<void> _addGroup() async {
    final result = await Navigator.of(context).push<OrgGroup>(
      slideRoute(builder: (_) => const OrgGroupFormScreen()),
    );
    if (result != null && mounted) setState(() => _groups.add(result));
  }

  Future<void> _editGroup(int index) async {
    final result = await Navigator.of(context).push<OrgGroup>(
      slideRoute(builder: (_) => OrgGroupFormScreen(group: _groups[index])),
    );
    if (result != null && mounted) setState(() => _groups[index] = result);
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

    if (_nameCtrl.text.trim().isEmpty || _selectedCategories.isEmpty) {
      setState(() => _submitted = true);
      _scrollToFirstError();
      return;
    }

    final catIds = _selectedCategories
        .map((c) => int.tryParse(c.id))
        .whereType<int>()
        .toList();

    if (_isEdit) {
      setState(() => _saving = true);
      try {
        final classId = int.tryParse(widget.orgClass!.id) ?? 0;
        await ApiService.updateClass(
          classId: classId,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isNotEmpty
              ? _descCtrl.text.trim()
              : null,
          categoryIds: catIds.isNotEmpty ? catIds : null,
          imageUrl: _imageUrl,
        );
        if (!mounted) return;
        Navigator.of(context).pop(OrgClass(
          id: widget.orgClass!.id,
          name: _nameCtrl.text.trim(),
          category: _selectedCategories.first.stableNameEn,
          categoryIds: _selectedCategories.map((c) => c.id).toList(),
          categoryList: _selectedCategories,
          description: _descCtrl.text.trim(),
          groups: _groups,
        ));
      } catch (_) {
        if (!mounted) return;
        _showSnack(AppLocalizations.of(context)!.failedToUpdateClass, const Color(0xFFEF4444));
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    setState(() => _saving = true);
    try {
      final orgIdInt = int.tryParse(widget.orgId ?? '') ?? 0;

      final classData = await ApiService.createClass(
        organizationId: orgIdInt,
        categoryIds: catIds.isNotEmpty ? catIds : null,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        imageUrl: _imageUrl,
      );
      final classId = classData['id'] as int;

      for (final group in _groups) {
        final groupData = await ApiService.createGroup(
          classId: classId,
          name: group.name,
          ageFrom: group.minAge > 0 ? group.minAge : null,
          ageTo: group.maxAge < 99 ? group.maxAge : null,
          capacity: group.capacity > 0 ? group.capacity : null,
        );
        final groupId = groupData['id'] as int;

        for (final slot in group.schedule) {
          await ApiService.createGroupSchedule(
            groupId: groupId,
            dayOfWeek: dayToInt(slot.day),
            startTime: fmtApiTime(slot.start),
            endTime: fmtApiTime(slot.end),
          );
        }
      }

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      _showSnack(l10n.classCreatedSuccess, const Color(0xFF059669));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.failedToCreateClass,
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
                    _sectionLabel(l10n.classDetailsSection),
                    const SizedBox(height: 12),
                    _buildFieldCard(
                      key: _detailsCardKey,
                      hasError: _submitted &&
                          (_nameCtrl.text.trim().isEmpty ||
                              _selectedCategories.isEmpty),
                      children: [
                        _inlineField(
                          ctrl: _nameCtrl,
                          hint: l10n.classNameHint,
                          icon: Icons.school_rounded,
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
                      _errorLabel(l10n.errorSelectCategory),
                    const SizedBox(height: 24),
                    _sectionLabel(l10n.groupsSection),
                    const SizedBox(height: 12),
                    _buildGroupsSection(),
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
            _isEdit
                ? AppLocalizations.of(context)!.editClass
                : AppLocalizations.of(context)!.btnNewClass,
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
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
              color: AppColors.purple.withValues(alpha: 0.4), width: 1.5),
        ),
        child: _imageUploading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purple))
            : hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _imageLocalPath != null
                            ? Image.file(File(_imageLocalPath!),
                                fit: BoxFit.cover)
                            : Image.network(_imageUrl!, fit: BoxFit.cover),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(AppLocalizations.of(context)!.tapToChange,
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.white)),
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
                          child: const Icon(Icons.add_photo_alternate_rounded,
                              color: Colors.white, size: 34),
                        ),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.uploadClassImage,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
    TextInputAction action = TextInputAction.next,
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
              textInputAction: action,
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
              child: Icon(Icons.category_rounded,
                  size: 20,
                  color: showError
                      ? const Color(0xFFEF4444)
                      : AppColors.textMuted),
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
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted, size: 22),
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
        border:
            Border.all(color: catColorStart(stable).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(catIcon(stable), size: 11, color: catColorStart(stable)),
          const SizedBox(width: 4),
          Text(cat.localizedName(locale),
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() =>
                _selectedCategories.removeWhere((c) => c.id == cat.id)),
            child: const Icon(Icons.close, size: 12, color: AppColors.textMuted),
          ),
        ],
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
                hintText: AppLocalizations.of(context)!.descriptionHint,
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

  Widget _buildGroupsSection() {
    return Column(
      children: [
        ..._groups.asMap().entries.map((e) {
          final i = e.key;
          final g = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.group_rounded,
                      color: AppColors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.name,
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Builder(builder: (ctx) {
                        final l10n = AppLocalizations.of(ctx)!;
                        return Text(
                          '${l10n.agesLabel} ${g.minAge}–${g.maxAge} · ₪${g.price.toStringAsFixed(0)}${l10n.perMonthSuffix} · ${g.capacity} ${l10n.studentsLabel}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textMuted),
                        );
                      }),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _editGroup(i),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 15, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _groups.removeAt(i)),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 15, color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ),
          );
        }),
        GestureDetector(
          onTap: _addGroup,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, color: AppColors.purple, size: 20),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                  child: Text(AppLocalizations.of(context)!.addGroup,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
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
              ? const LinearGradient(
                  colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)])
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
              : Builder(builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx)!;
                  return Text(
                    _isEdit ? l10n.btnSaveChanges : l10n.createClass,
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: Colors.white),
                  );
                }),
        ),
      ),
    );
  }
}
