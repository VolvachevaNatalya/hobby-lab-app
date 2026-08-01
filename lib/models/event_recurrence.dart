import '../l10n/app_localizations.dart';

class EventRecurrence {
  final int? id;
  final String frequency;
  final int interval;
  final String endType;
  final int? totalCount;
  final String? endDate;
  final String? generatedUntil;
  final String? status;

  const EventRecurrence({
    this.id,
    required this.frequency,
    required this.interval,
    required this.endType,
    this.totalCount,
    this.endDate,
    this.generatedUntil,
    this.status,
  });

  factory EventRecurrence.fromJson(Map<String, dynamic> json) =>
      EventRecurrence(
        id: json['id'] as int?,
        frequency: (json['frequency'] ?? 'daily').toString(),
        interval: (json['interval'] as num?)?.toInt() ?? 1,
        endType: (json['end_type'] ?? 'never').toString(),
        totalCount: json['total_count'] as int?,
        endDate: json['end_date']?.toString(),
        generatedUntil: json['generated_until']?.toString(),
        status: json['status']?.toString(),
      );
}

class RecurrenceInput {
  final String frequency;
  final int interval;
  final String endType;
  final int? totalCount;
  final String? endDate;

  const RecurrenceInput({
    required this.frequency,
    required this.interval,
    required this.endType,
    this.totalCount,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'frequency': frequency,
      'interval': interval,
      'end_type': endType,
    };
    if (endType == 'count' && totalCount != null) m['total_count'] = totalCount;
    if (endType == 'date' && endDate != null) m['end_date'] = endDate;
    return m;
  }
}

// ─── Display helpers ──────────────────────────────────────────────────────────

String recurrenceFrequencyText(EventRecurrence r, AppLocalizations l10n) {
  if (r.interval == 1) {
    return switch (r.frequency) {
      'daily' => l10n.repeatsDaily,
      'weekly' => l10n.repeatsWeekly,
      'monthly' => l10n.repeatsMonthly,
      'yearly' => l10n.repeatsYearly,
      _ => r.frequency,
    };
  }
  return switch (r.frequency) {
    'daily' => l10n.repeatsEveryNDays(r.interval),
    'weekly' => l10n.repeatsEveryNWeeks(r.interval),
    'monthly' => l10n.repeatsEveryNMonths(r.interval),
    'yearly' => l10n.repeatsEveryNYears(r.interval),
    _ => '${r.frequency} (${r.interval})',
  };
}

String recurrenceEndText(EventRecurrence r, AppLocalizations l10n) {
  if (r.endType == 'count' && r.totalCount != null) {
    return l10n.repeatCountSummary(r.totalCount!);
  }
  if (r.endType == 'date' && r.endDate != null) {
    try {
      final dt = DateTime.parse(r.endDate!);
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
      return l10n.repeatUntilDate('${dt.day} ${months[dt.month]} ${dt.year}');
    } catch (_) {
      return l10n.repeatUntilDate(r.endDate!);
    }
  }
  return l10n.repeatNoEndDate;
}

String recurrenceInputSummary(RecurrenceInput r, AppLocalizations l10n) {
  if (r.interval == 1) {
    return switch (r.frequency) {
      'daily' => l10n.repeatPickerDaily,
      'weekly' => l10n.repeatPickerWeekly,
      'monthly' => l10n.repeatPickerMonthly,
      'yearly' => l10n.repeatPickerYearly,
      _ => r.frequency,
    };
  }
  return switch (r.frequency) {
    'daily' => l10n.repeatsEveryNDays(r.interval),
    'weekly' => l10n.repeatsEveryNWeeks(r.interval),
    'monthly' => l10n.repeatsEveryNMonths(r.interval),
    'yearly' => l10n.repeatsEveryNYears(r.interval),
    _ => '${l10n.repeatEveryLabel} ${r.interval}',
  };
}
