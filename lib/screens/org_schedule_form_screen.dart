import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/org_models.dart';
import '../services/api_service.dart';

const _kDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class _Slot {
  String day;
  TimeOfDay start;
  TimeOfDay end;

  _Slot({
    this.day = 'Sun',
    this.start = const TimeOfDay(hour: 9, minute: 0),
    this.end = const TimeOfDay(hour: 10, minute: 0),
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class OrgScheduleFormScreen extends StatefulWidget {
  final List<OrgScheduleSlot> initial;
  final String? groupId;

  const OrgScheduleFormScreen({super.key, this.initial = const [], this.groupId});

  @override
  State<OrgScheduleFormScreen> createState() => _OrgScheduleFormScreenState();
}

class _OrgScheduleFormScreenState extends State<OrgScheduleFormScreen> {
  late List<_Slot> _slots;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _slots = widget.initial.isEmpty
        ? [_Slot()]
        : widget.initial
            .map((s) => _Slot(day: s.day, start: s.start, end: s.end))
            .toList();
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final initial = isStart ? _slots[index].start : _slots[index].end;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) =>
          Theme(data: darkPickerTheme(ctx), child: child!),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _slots[index].start = picked;
        } else {
          _slots[index].end = picked;
        }
      });
    }
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
    // Standalone mode: groupId provided — save directly to API
    if (widget.groupId != null) {
      setState(() => _saving = true);
      try {
        final groupIdInt = int.tryParse(widget.groupId!) ?? 0;
        for (final slot in _slots) {
          await ApiService.createGroupSchedule(
            groupId: groupIdInt,
            dayOfWeek: dayToInt(slot.day),
            startTime: fmtApiTime(slot.start),
            endTime: fmtApiTime(slot.end),
          );
        }
        if (!mounted) return;
        _showSnack(AppLocalizations.of(context)!.scheduleSavedSuccess, const Color(0xFF059669));
        Navigator.of(context).pop();
      } catch (_) {
        if (!mounted) return;
        _showSnack(AppLocalizations.of(context)!.failedToSaveSchedule,
            const Color(0xFFEF4444));
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    // Embedded mode: return slots to parent
    final result = _slots
        .map((s) => OrgScheduleSlot(day: s.day, start: s.start, end: s.end))
        .toList();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
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
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ..._slots.asMap().entries.map((e) => _SlotCard(
                        slot: e.value,
                        index: e.key,
                        canDelete: _slots.length > 1,
                        onDayChanged: (d) =>
                            setState(() => _slots[e.key].day = d),
                        onPickStart: () => _pickTime(e.key, true),
                        onPickEnd: () => _pickTime(e.key, false),
                        onDelete: () =>
                            setState(() => _slots.removeAt(e.key)),
                      )),
                  const SizedBox(height: 8),
                  _buildAddBtn(),
                  const SizedBox(height: 32),
                  _buildSaveBtn(),
                ],
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
            AppLocalizations.of(context)!.addSchedule,
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

  Widget _buildAddBtn() {
    return GestureDetector(
      onTap: () => setState(() => _slots.add(_Slot())),
      child: Container(
        height: 52,
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
              shaderCallback: (b) =>
                  AppColors.brandGradient.createShader(b),
              child: Text(
                AppLocalizations.of(context)!.addAnotherTimeSlot,
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

  Widget _buildSaveBtn() {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: Container(
        height: 56,
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
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  AppLocalizations.of(context)!.saveSchedule,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Slot card ────────────────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  final _Slot slot;
  final int index;
  final bool canDelete;
  final ValueChanged<String> onDayChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onDelete;

  const _SlotCard({
    required this.slot,
    required this.index,
    required this.canDelete,
    required this.onDayChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localDays = [
      l10n.daySunAbbrev, l10n.dayMonAbbrev, l10n.dayTueAbbrev,
      l10n.dayWedAbbrev, l10n.dayThuAbbrev, l10n.dayFriAbbrev, l10n.daySatAbbrev,
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.slotLabel(index + 1),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (canDelete)
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Color(0xFFEF4444)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l10n.dayOfWeekLabel,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _kDays.asMap().entries.map((e) {
              final day = e.value;
              final displayDay = localDays[e.key];
              final sel = slot.day == day;
              return GestureDetector(
                onTap: () => onDayChanged(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: sel ? AppColors.brandGradient : null,
                    color: sel ? null : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: sel
                            ? Colors.transparent
                            : AppColors.divider),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.purple.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    displayDay,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          sel ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.timeLabel,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TimeBtn(time: slot.start, onTap: onPickStart),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '→',
                  style: GoogleFonts.poppins(
                      color: AppColors.textMuted, fontSize: 18),
                ),
              ),
              _TimeBtn(time: slot.end, onTap: onPickEnd),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeBtn extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeBtn({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
        ),
        child: Text(
          fmtTime(time),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.purpleLight,
          ),
        ),
      ),
    );
  }
}
