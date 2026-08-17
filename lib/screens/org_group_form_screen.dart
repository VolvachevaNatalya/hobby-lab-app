import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/org_models.dart';
import '../services/api_service.dart';
import 'org_schedule_form_screen.dart';
import '../routing/transitions.dart';

class OrgGroupFormScreen extends StatefulWidget {
  final OrgGroup? group;
  final String? classId;

  const OrgGroupFormScreen({super.key, this.group, this.classId});

  @override
  State<OrgGroupFormScreen> createState() => _OrgGroupFormScreenState();
}

class _OrgGroupFormScreenState extends State<OrgGroupFormScreen> {
  final _nameCtrl = TextEditingController();
  final _minAgeCtrl = TextEditingController();
  final _maxAgeCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  final _nameKey = GlobalKey();

  List<OrgScheduleSlot> _schedule = [];
  bool _saving = false;
  bool _submitted = false;

  bool get _isEdit => widget.group != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onFieldChanged);
    final g = widget.group;
    if (g != null) {
      _nameCtrl.text = g.name;
      _minAgeCtrl.text = g.minAge.toString();
      _maxAgeCtrl.text = g.maxAge.toString();
      _capacityCtrl.text = g.capacity.toString();
      _priceCtrl.text = g.price.toStringAsFixed(0);
      _schedule = List.from(g.schedule);
    }
  }

  void _onFieldChanged() {
    if (_submitted && mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onFieldChanged);
    _nameCtrl.dispose();
    _minAgeCtrl.dispose();
    _maxAgeCtrl.dispose();
    _capacityCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _editSchedule() async {
    final result = await Navigator.of(context).push<List<OrgScheduleSlot>>(
      slideRoute(builder: (_) => OrgScheduleFormScreen(initial: _schedule)),
    );
    if (result != null && mounted) setState(() => _schedule = result);
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

    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _submitted = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_nameKey.currentContext != null) {
          Scrollable.ensureVisible(
            _nameKey.currentContext!,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      });
      return;
    }

    // Standalone mode: classId provided — save directly to API
    if (widget.classId != null && !_isEdit) {
      setState(() => _saving = true);
      try {
        final classIdInt = int.tryParse(widget.classId!) ?? 0;
        final groupData = await ApiService.createGroup(
          classId: classIdInt,
          name: _nameCtrl.text.trim(),
          ageFrom: int.tryParse(_minAgeCtrl.text),
          ageTo: int.tryParse(_maxAgeCtrl.text),
          capacity: int.tryParse(_capacityCtrl.text),
        );
        final groupId = groupData['id'] as int;

        for (final slot in _schedule) {
          await ApiService.createGroupSchedule(
            groupId: groupId,
            dayOfWeek: dayToInt(slot.day),
            startTime: fmtApiTime(slot.start),
            endTime: fmtApiTime(slot.end),
          );
        }

        if (!mounted) return;
        _showSnack(AppLocalizations.of(context)!.groupCreatedSuccess, const Color(0xFF059669));
        Navigator.of(context).pop();
      } catch (_) {
        if (!mounted) return;
        _showSnack(AppLocalizations.of(context)!.failedToCreateGroup,
            const Color(0xFFEF4444));
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    // Embedded mode: return OrgGroup to parent (class form orchestrates API)
    final group = OrgGroup(
      name: _nameCtrl.text.trim(),
      minAge: int.tryParse(_minAgeCtrl.text) ?? 0,
      maxAge: int.tryParse(_maxAgeCtrl.text) ?? 120,
      capacity: int.tryParse(_capacityCtrl.text) ?? 15,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      schedule: _schedule,
    );
    Navigator.of(context).pop(group);
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
                    _sectionLabel(l10n.groupDetailsSection),
                    const SizedBox(height: 12),
                    _buildFieldCard(
                      key: _nameKey,
                      hasError: _submitted && _nameCtrl.text.trim().isEmpty,
                      children: [
                        _inlineField(
                          ctrl: _nameCtrl,
                          hint: l10n.groupNameHint,
                          icon: Icons.group_rounded,
                          isRequired: true,
                          error: _submitted && _nameCtrl.text.trim().isEmpty,
                        ),
                      ],
                    ),
                    if (_submitted && _nameCtrl.text.trim().isEmpty)
                      _errorLabel(l10n.fieldRequired),
                    const SizedBox(height: 20),
                    _sectionLabel(l10n.ageRangeSection),
                    const SizedBox(height: 12),
                    _buildFieldCard(children: [_ageRangeRow()]),
                    const SizedBox(height: 20),
                    _sectionLabel(l10n.capacityPriceSection),
                    const SizedBox(height: 12),
                    _buildFieldCard(children: [
                      _inlineField(
                        ctrl: _capacityCtrl,
                        hint: l10n.maxStudentsHint,
                        icon: Icons.people_rounded,
                        type: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      _divider(),
                      _inlineField(
                        ctrl: _priceCtrl,
                        hint: l10n.pricePerMonthHint,
                        icon: Icons.payments_rounded,
                        type: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                        action: TextInputAction.done,
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _sectionLabel(l10n.scheduleSection),
                    const SizedBox(height: 12),
                    _buildScheduleSection(),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _isEdit
                ? AppLocalizations.of(context)!.editGroup
                : AppLocalizations.of(context)!.newGroup,
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

  static const _requiredStyle = TextStyle(
    color: Color(0xFFEF4444),
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  Widget _errorLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, top: 4),
    child: Text(text, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFEF4444))),
  );

  Widget _divider() => const Divider(
      height: 1, thickness: 1, color: AppColors.divider, indent: 52);

  Widget _inlineField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    List<TextInputFormatter>? formatters,
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
              inputFormatters: formatters,
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

  Widget _ageRangeRow() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.child_care_rounded,
              size: 20, color: AppColors.textMuted),
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
                hintText: l10n.minAgeHint,
                hintStyle: GoogleFonts.poppins(
                    color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16),
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
                hintText: l10n.maxAgeHint,
                hintStyle: GoogleFonts.poppins(
                    color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _localizeDay(String day, AppLocalizations l10n) => switch (day) {
    'Sun' => l10n.daySunAbbrev,
    'Mon' => l10n.dayMonAbbrev,
    'Tue' => l10n.dayTueAbbrev,
    'Wed' => l10n.dayWedAbbrev,
    'Thu' => l10n.dayThuAbbrev,
    'Fri' => l10n.dayFriAbbrev,
    'Sat' => l10n.daySatAbbrev,
    _ => day,
  };

  Widget _buildScheduleSection() {
    final l10n = AppLocalizations.of(context)!;
    if (_schedule.isEmpty) {
      return GestureDetector(
        onTap: _editSchedule,
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
              const Icon(Icons.calendar_month_rounded,
                  color: AppColors.purple, size: 20),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (b) =>
                    AppColors.brandGradient.createShader(b),
                child: Text(
                  l10n.addSchedule,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.timeSlotCount(_schedule.length),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _editSchedule,
                child: ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.brandGradient.createShader(b),
                  child: Text(
                    l10n.btnEdit,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _schedule.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${_localizeDay(s.day, l10n)} ${fmtTime(s.start)}–${fmtTime(s.end)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.purpleLight,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Builder(builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx)!;
                  return Text(
                    _isEdit ? l10n.btnSaveChanges : l10n.addGroup,
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
