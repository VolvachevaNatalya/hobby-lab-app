import 'package:flutter/material.dart';

String _fmtT(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

String _fmtD(DateTime dt, List<String> months) =>
    '${dt.day} ${months[dt.month]} ${dt.year}';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Formats a string date+time for an AppEvent (ISO 8601 string inputs).
/// Returns null when startIso is null/unparseable.
///
/// No end:     "29 Aug 2026 · 10:00"
/// Same-day:   "29 Aug 2026 · 10:00-18:00"
/// Multi-day:  "29 Aug 2026, 10:00 - 31 Aug 2026, 18:00"
String? fmtEventDateTime(
  String? startIso,
  String? endIso,
  List<String> months,
) {
  if (startIso == null) return null;
  final start = DateTime.tryParse(startIso);
  if (start == null) return null;

  final startDate = _fmtD(start, months);
  final startTime = _fmtT(start);

  if (endIso == null) return '$startDate · $startTime';
  final end = DateTime.tryParse(endIso);
  if (end == null) return '$startDate · $startTime';

  final endTime = _fmtT(end);

  if (_sameDay(start, end)) {
    return '$startDate · $startTime-$endTime';
  }

  final endDate = _fmtD(end, months);
  return '$startDate, $startTime - $endDate, $endTime';
}

/// Formats date+time for an OrgEvent (DateTime + TimeOfDay inputs).
///
/// No end:     "29 Aug 2026 · 10:00"
/// Same-day:   "29 Aug 2026 · 10:00-18:00"
/// Multi-day:  "29 Aug 2026, 10:00 - 31 Aug 2026, 18:00"
String fmtOrgEventDateTime(
  DateTime date,
  TimeOfDay time,
  DateTime? endDateTime,
  List<String> months,
) {
  final dateStr = _fmtD(date, months);
  final timeStr =
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  if (endDateTime == null) return '$dateStr · $timeStr';

  final endTime = _fmtT(endDateTime);

  if (_sameDay(date, endDateTime)) {
    return '$dateStr · $timeStr-$endTime';
  }

  final endDateStr = _fmtD(endDateTime, months);
  return '$dateStr, $timeStr - $endDateStr, $endTime';
}

/// Returns only the start time part, extended with end time when available.
/// Used in places that already have a separate date display.
///
/// No end:    "10:00"
/// Same-day:  "10:00-18:00"
/// Multi-day: "10:00"  (start time only — end date is shown separately)
String fmtOrgEventTimeDisplay(TimeOfDay time, DateTime? endDateTime, DateTime date) {
  final timeStr =
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  if (endDateTime == null) return timeStr;
  if (_sameDay(date, endDateTime)) {
    final endTime = _fmtT(endDateTime);
    return '$timeStr-$endTime';
  }
  return timeStr;
}
