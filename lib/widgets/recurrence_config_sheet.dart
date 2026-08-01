import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/event_recurrence.dart';
import '../models/org_models.dart';
import '../l10n/app_localizations.dart';

Future<RecurrenceInput?> showRecurrenceConfigSheet(
  BuildContext context, {
  RecurrenceInput? current,
  DateTime? eventDate,
}) {
  return showModalBottomSheet<RecurrenceInput>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) =>
        _RecurrenceConfigSheet(current: current, eventDate: eventDate),
  );
}

class _RecurrenceConfigSheet extends StatefulWidget {
  final RecurrenceInput? current;
  final DateTime? eventDate;

  const _RecurrenceConfigSheet({this.current, this.eventDate});

  @override
  State<_RecurrenceConfigSheet> createState() => _RecurrenceConfigSheetState();
}

class _RecurrenceConfigSheetState extends State<_RecurrenceConfigSheet> {
  late String _frequency;
  late int _interval;
  late String _endType;
  DateTime? _endDate;
  bool _submitted = false;

  late final TextEditingController _intervalCtrl;
  late final TextEditingController _countCtrl;

  @override
  void initState() {
    super.initState();
    final r = widget.current;
    _frequency = r?.frequency ?? 'weekly';
    _interval = r?.interval ?? 1;
    _endType = r?.endType ?? 'never';
    final count = r?.totalCount ?? 2;
    _endDate = r?.endDate != null ? DateTime.tryParse(r!.endDate!) : null;
    _intervalCtrl = TextEditingController(text: _interval.toString());
    _countCtrl = TextEditingController(text: count.toString());
  }

  @override
  void dispose() {
    _intervalCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  bool get _intervalValid {
    final v = int.tryParse(_intervalCtrl.text);
    return v != null && v >= 1;
  }

  bool get _countValid {
    final v = int.tryParse(_countCtrl.text);
    return v != null && v >= 2;
  }

  bool get _endDateValid {
    if (_endDate == null) return false;
    if (widget.eventDate != null) {
      final evDate = DateTime(
        widget.eventDate!.year,
        widget.eventDate!.month,
        widget.eventDate!.day,
      );
      final endDateOnly = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
      );
      return !endDateOnly.isBefore(evDate);
    }
    return true;
  }

  void _save() {
    setState(() => _submitted = true);
    if (!_intervalValid) return;
    if (_endType == 'count' && !_countValid) return;
    if (_endType == 'date' && !_endDateValid) return;

    Navigator.of(context).pop(
      RecurrenceInput(
        frequency: _frequency,
        interval: int.parse(_intervalCtrl.text),
        endType: _endType,
        totalCount: _endType == 'count' ? int.parse(_countCtrl.text) : null,
        endDate: _endType == 'date'
            ? '${_endDate!.year.toString().padLeft(4, '0')}-'
                  '${_endDate!.month.toString().padLeft(2, '0')}-'
                  '${_endDate!.day.toString().padLeft(2, '0')}'
            : null,
      ),
    );
  }

  Future<void> _pickEndDate() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _endDate ??
          (widget.eventDate ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: widget.eventDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(data: darkPickerTheme(ctx), child: child!),
      helpText: l10n.repeatOnDateOption,
    );
    if (picked != null && mounted) setState(() => _endDate = picked);
  }

  String _unitLabelPlural(String freq, AppLocalizations l10n) => switch (freq) {
    'daily' => '${l10n.repeatUnitDay}s',
    'weekly' => '${l10n.repeatUnitWeek}s',
    'monthly' => '${l10n.repeatUnitMonth}s',
    'yearly' => '${l10n.repeatUnitYear}s',
    _ => freq,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.repeatPickerCustom,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Divider(color: AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(l10n.repeatEveryLabel),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: _numberField(
                            controller: _intervalCtrl,
                            hasError: _submitted && !_intervalValid,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _unitDropdown(l10n)),
                      ],
                    ),
                    if (_submitted && !_intervalValid)
                      _errorLabel(l10n.repeatMinCountError),
                    const SizedBox(height: 20),
                    _sectionLabel(l10n.repeatEndsLabel),
                    const SizedBox(height: 10),
                    _endOption(
                      label: l10n.repeatNeverOption,
                      icon: Icons.all_inclusive_rounded,
                      value: 'never',
                      l10n: l10n,
                    ),
                    const SizedBox(height: 8),
                    _endOption(
                      label: l10n.repeatAfterEventsOption,
                      icon: Icons.format_list_numbered_rounded,
                      value: 'count',
                      l10n: l10n,
                    ),
                    if (_endType == 'count') ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 160,
                              child: _numberField(
                                controller: _countCtrl,
                                hint: l10n.numberOfEventsHint,
                                hasError: _submitted && !_countValid,
                              ),
                            ),
                            if (_submitted && !_countValid)
                              _errorLabel(l10n.repeatMinCountError)
                            else
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  l10n.firstEventIncludedNote,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _endOption(
                      label: l10n.repeatOnDateOption,
                      icon: Icons.calendar_today_rounded,
                      value: 'date',
                      l10n: l10n,
                    ),
                    if (_endType == 'date') ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _pickEndDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (_submitted && !_endDateValid)
                                        ? const Color(0xFFEF4444)
                                        : AppColors.divider,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 15,
                                      color: _endDate != null
                                          ? AppColors.purple
                                          : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _endDate != null
                                          ? '${_endDate!.day} ${_monthName(_endDate!.month)} ${_endDate!.year}'
                                          : l10n.repeatOnDateOption,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: _endDate != null
                                            ? AppColors.textPrimary
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_submitted && !_endDateValid)
                              _errorLabel(l10n.repeatEndDateError),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            l10n.btnSave,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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

  Widget _unitDropdown(AppLocalizations l10n) {
    final items = ['daily', 'weekly', 'monthly', 'yearly'];
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _frequency,
          dropdownColor: AppColors.surfaceElevated,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          isExpanded: true,
          items: items
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(_unitLabelPlural(f, l10n)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _frequency = v);
          },
        ),
      ),
    );
  }

  Widget _endOption({
    required String label,
    required IconData icon,
    required String value,
    required AppLocalizations l10n,
  }) {
    final selected = _endType == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _endType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple.withValues(alpha: 0.08)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.purple.withValues(alpha: 0.4)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.purple : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.purpleLight
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: AppColors.purple,
              ),
          ],
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    String? hint,
    bool hasError = false,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? const Color(0xFFEF4444) : AppColors.divider,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
        cursorColor: AppColors.purple,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 10,
          ),
        ),
        onChanged: (_) {
          if (_submitted) setState(() {});
        },
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
      letterSpacing: 0.5,
    ),
  );

  Widget _errorLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      text,
      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFEF4444)),
    ),
  );

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}
