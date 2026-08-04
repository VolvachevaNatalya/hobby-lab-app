import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/event_recurrence.dart';
import '../l10n/app_localizations.dart';
import 'recurrence_config_sheet.dart';

/// Shows the recurrence frequency picker bottom sheet.
/// Calls [onClear] when "Does not repeat" is selected.
/// Calls [onSelect] when a recurrence is chosen.
Future<void> showRecurrencePicker(
  BuildContext context, {
  RecurrenceInput? current,
  DateTime? eventDate,
  required void Function() onClear,
  required void Function(RecurrenceInput) onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _RecurrencePicker(
      current: current,
      eventDate: eventDate,
      onClear: onClear,
      onSelect: onSelect,
    ),
  );
}

class _RecurrencePicker extends StatelessWidget {
  final RecurrenceInput? current;
  final DateTime? eventDate;
  final void Function() onClear;
  final void Function(RecurrenceInput) onSelect;

  const _RecurrencePicker({
    required this.current,
    required this.eventDate,
    required this.onClear,
    required this.onSelect,
  });

  bool _isSelected(String frequency, int interval) =>
      current?.frequency == frequency && current?.interval == interval;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Container(
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
                l10n.repeatSection,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(color: AppColors.divider, height: 20),
            _Option(
              label: l10n.doesNotRepeat,
              icon: Icons.block_rounded,
              selected: current == null,
              onTap: () {
                Navigator.of(context).pop();
                onClear();
              },
            ),
            _Option(
              label: l10n.repeatPickerDaily,
              icon: Icons.today_rounded,
              selected: _isSelected('daily', 1),
              onTap: () async {
                final seed = RecurrenceInput(
                  frequency: 'daily',
                  interval: 1,
                  endType: current?.frequency == 'daily'
                      ? current!.endType
                      : 'never',
                  totalCount: current?.frequency == 'daily'
                      ? current?.totalCount
                      : null,
                  endDate: current?.frequency == 'daily'
                      ? current?.endDate
                      : null,
                );
                final result = await showRecurrenceConfigSheet(
                  context,
                  current: seed,
                  eventDate: eventDate,
                );
                if (result != null && context.mounted) {
                  Navigator.of(context).pop();
                  onSelect(result);
                }
              },
            ),
            _Option(
              label: l10n.repeatPickerWeekly,
              icon: Icons.view_week_rounded,
              selected: _isSelected('weekly', 1),
              onTap: () async {
                final seed = RecurrenceInput(
                  frequency: 'weekly',
                  interval: 1,
                  endType: current?.frequency == 'weekly'
                      ? current!.endType
                      : 'never',
                  totalCount: current?.frequency == 'weekly'
                      ? current?.totalCount
                      : null,
                  endDate: current?.frequency == 'weekly'
                      ? current?.endDate
                      : null,
                );
                final result = await showRecurrenceConfigSheet(
                  context,
                  current: seed,
                  eventDate: eventDate,
                );
                if (result != null && context.mounted) {
                  Navigator.of(context).pop();
                  onSelect(result);
                }
              },
            ),
            _Option(
              label: l10n.repeatPickerMonthly,
              icon: Icons.calendar_month_rounded,
              selected: _isSelected('monthly', 1),
              onTap: () async {
                final seed = RecurrenceInput(
                  frequency: 'monthly',
                  interval: 1,
                  endType: current?.frequency == 'monthly'
                      ? current!.endType
                      : 'never',
                  totalCount: current?.frequency == 'monthly'
                      ? current?.totalCount
                      : null,
                  endDate: current?.frequency == 'monthly'
                      ? current?.endDate
                      : null,
                );
                final result = await showRecurrenceConfigSheet(
                  context,
                  current: seed,
                  eventDate: eventDate,
                );
                if (result != null && context.mounted) {
                  Navigator.of(context).pop();
                  onSelect(result);
                }
              },
            ),
            _Option(
              label: l10n.repeatPickerYearly,
              icon: Icons.event_repeat_rounded,
              selected: _isSelected('yearly', 1),
              onTap: () async {
                final seed = RecurrenceInput(
                  frequency: 'yearly',
                  interval: 1,
                  endType: current?.frequency == 'yearly'
                      ? current!.endType
                      : 'never',
                  totalCount: current?.frequency == 'yearly'
                      ? current?.totalCount
                      : null,
                  endDate: current?.frequency == 'yearly'
                      ? current?.endDate
                      : null,
                );
                final result = await showRecurrenceConfigSheet(
                  context,
                  current: seed,
                  eventDate: eventDate,
                );
                if (result != null && context.mounted) {
                  Navigator.of(context).pop();
                  onSelect(result);
                }
              },
            ),
            _Option(
              label: l10n.repeatPickerCustom,
              icon: Icons.tune_rounded,
              selected: current != null &&
                  !_isSelected('daily', 1) &&
                  !_isSelected('weekly', 1) &&
                  !_isSelected('monthly', 1) &&
                  !_isSelected('yearly', 1),
              onTap: () async {
                final result = await showRecurrenceConfigSheet(
                  context,
                  current: current,
                  eventDate: eventDate,
                );
                if (result != null && context.mounted) {
                  Navigator.of(context).pop();
                  onSelect(result);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.purple : AppColors.textMuted,
            ),
            const SizedBox(width: 14),
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
                color: AppColors.purple,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
