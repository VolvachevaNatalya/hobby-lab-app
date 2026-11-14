import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_lab/utils/event_date_formatter.dart';

void main() {
  // Deterministic 12-element month list for tests (English abbreviations).
  // Index 0 = Jan … Index 11 = Dec — all formatters now use this convention.
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  const ruMonths = [
    'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];

  const heMonths = [
    'ינו', 'פבר', 'מרץ', 'אפר', 'מאי', 'יונ',
    'יול', 'אוג', 'ספט', 'אוק', 'נוב', 'דצמ',
  ];

  // ── fmtReviewDate ────────────────────────────────────────────────────────────

  group('fmtReviewDate', () {
    test('formats ISO date as "D MMM YYYY"', () {
      expect(fmtReviewDate('2026-08-05T10:00:00', months), '5 Aug 2026');
    });

    test('formats day without leading zero', () {
      expect(fmtReviewDate('2026-01-01T00:00:00', months), '1 Jan 2026');
    });

    test('formats December correctly (last month, index 11)', () {
      expect(fmtReviewDate('2025-12-31T23:59:59', months), '31 Dec 2025');
    });

    test('formats January correctly (first month, index 0)', () {
      expect(fmtReviewDate('2026-01-15T08:30:00', months), '15 Jan 2026');
    });

    test('returns empty string for null input', () {
      expect(fmtReviewDate(null, months), '');
    });

    test('returns empty string for empty string input', () {
      expect(fmtReviewDate('', months), '');
    });

    test('returns empty string for unparseable input', () {
      expect(fmtReviewDate('not-a-date', months), '');
    });

    test('month abbreviation reflects the months list (locale slot)', () {
      const ruMonths = [
        'янв', 'фев', 'мар', 'апр', 'май', 'июн',
        'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
      ];
      expect(fmtReviewDate('2026-08-05T10:00:00', ruMonths), '5 авг 2026');
    });

    test('month abbreviation reflects Hebrew months list', () {
      const heMonths = [
        'ינו', 'פבר', 'מרץ', 'אפר', 'מאי', 'יונ',
        'יול', 'אוג', 'ספט', 'אוק', 'נוב', 'דצמ',
      ];
      expect(fmtReviewDate('2026-03-20T12:00:00', heMonths), '20 מרץ 2026');
    });
  });

  // ── fmtOrgDate ────────────────────────────────────────────────────────────────

  group('fmtOrgDate', () {
    test('formats a DateTime as "D MMM YYYY" (English)', () {
      expect(fmtOrgDate(DateTime(2026, 8, 5), months), '5 Aug 2026');
    });

    test('formats day without leading zero', () {
      expect(fmtOrgDate(DateTime(2026, 1, 3), months), '3 Jan 2026');
    });

    test('formats January correctly (index 0)', () {
      expect(fmtOrgDate(DateTime(2026, 1, 15), months), '15 Jan 2026');
    });

    test('formats December correctly (index 11)', () {
      expect(fmtOrgDate(DateTime(2025, 12, 31), months), '31 Dec 2025');
    });

    test('month abbreviation reflects Russian months list', () {
      const ruMonths = [
        'янв', 'фев', 'мар', 'апр', 'май', 'июн',
        'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
      ];
      expect(fmtOrgDate(DateTime(2026, 11, 7), ruMonths), '7 ноя 2026');
    });

    test('month abbreviation reflects Hebrew months list', () {
      const heMonths = [
        'ינו', 'פבר', 'מרץ', 'אפר', 'מאי', 'יונ',
        'יול', 'אוג', 'ספט', 'אוק', 'נוב', 'דצמ',
      ];
      expect(fmtOrgDate(DateTime(2026, 4, 20), heMonths), '20 אפר 2026');
    });

    test('all twelve months are reachable (no off-by-one)', () {
      for (var m = 1; m <= 12; m++) {
        final result = fmtOrgDate(DateTime(2026, m, 1), months);
        expect(result, contains(months[m - 1]),
            reason: 'month $m should produce ${months[m - 1]}');
      }
    });
  });

  // ── fmtEventDateTime ──────────────────────────────────────────────────────────

  group('fmtEventDateTime', () {
    test('formats January correctly (index 0)', () {
      expect(
        fmtEventDateTime('2026-01-15T10:00:00', null, months),
        '15 Jan 2026 · 10:00',
      );
    });

    test('formats December correctly (index 11)', () {
      expect(
        fmtEventDateTime('2025-12-31T23:00:00', null, months),
        '31 Dec 2025 · 23:00',
      );
    });

    test('all twelve months produce correct abbreviation', () {
      for (var m = 1; m <= 12; m++) {
        final iso = '2026-${m.toString().padLeft(2, '0')}-05T09:00:00';
        final result = fmtEventDateTime(iso, null, months);
        expect(result, contains(months[m - 1]),
            reason: 'month $m should produce ${months[m - 1]}');
      }
    });

    test('formats same-day range (start and end time)', () {
      expect(
        fmtEventDateTime('2026-08-05T10:00:00', '2026-08-05T18:00:00', months),
        '5 Aug 2026 · 10:00-18:00',
      );
    });

    test('formats multi-day range', () {
      expect(
        fmtEventDateTime('2026-08-05T10:00:00', '2026-08-07T18:00:00', months),
        '5 Aug 2026, 10:00 - 7 Aug 2026, 18:00',
      );
    });

    test('multi-day range spanning month boundary uses correct months', () {
      expect(
        fmtEventDateTime('2026-01-30T09:00:00', '2026-02-02T17:00:00', months),
        '30 Jan 2026, 09:00 - 2 Feb 2026, 17:00',
      );
    });

    test('month abbreviation reflects Russian months list', () {
      expect(
        fmtEventDateTime('2026-11-07T12:00:00', null, ruMonths),
        '7 ноя 2026 · 12:00',
      );
    });

    test('month abbreviation reflects Hebrew months list', () {
      expect(
        fmtEventDateTime('2026-03-20T08:30:00', null, heMonths),
        '20 מרץ 2026 · 08:30',
      );
    });

    test('returns null for null startIso', () {
      expect(fmtEventDateTime(null, null, months), isNull);
    });

    test('returns null for unparseable startIso', () {
      expect(fmtEventDateTime('not-a-date', null, months), isNull);
    });
  });

  // ── fmtOrgEventDateTime ───────────────────────────────────────────────────────

  group('fmtOrgEventDateTime', () {
    test('formats January correctly (index 0)', () {
      expect(
        fmtOrgEventDateTime(
          DateTime(2026, 1, 15),
          const TimeOfDay(hour: 10, minute: 0),
          null,
          months,
        ),
        '15 Jan 2026 · 10:00',
      );
    });

    test('formats December correctly (index 11)', () {
      expect(
        fmtOrgEventDateTime(
          DateTime(2025, 12, 31),
          const TimeOfDay(hour: 23, minute: 59),
          null,
          months,
        ),
        '31 Dec 2025 · 23:59',
      );
    });

    test('all twelve months produce correct abbreviation', () {
      for (var m = 1; m <= 12; m++) {
        final result = fmtOrgEventDateTime(
          DateTime(2026, m, 1),
          const TimeOfDay(hour: 9, minute: 0),
          null,
          months,
        );
        expect(result, contains(months[m - 1]),
            reason: 'month $m should produce ${months[m - 1]}');
      }
    });

    test('formats same-day range', () {
      expect(
        fmtOrgEventDateTime(
          DateTime(2026, 8, 5),
          const TimeOfDay(hour: 10, minute: 0),
          DateTime(2026, 8, 5, 18, 0),
          months,
        ),
        '5 Aug 2026 · 10:00-18:00',
      );
    });

    test('formats multi-day range', () {
      expect(
        fmtOrgEventDateTime(
          DateTime(2026, 8, 5),
          const TimeOfDay(hour: 10, minute: 0),
          DateTime(2026, 8, 7, 18, 0),
          months,
        ),
        '5 Aug 2026, 10:00 - 7 Aug 2026, 18:00',
      );
    });

    test('month abbreviation reflects Russian months list', () {
      expect(
        fmtOrgEventDateTime(
          DateTime(2026, 5, 9),
          const TimeOfDay(hour: 11, minute: 0),
          null,
          ruMonths,
        ),
        '9 май 2026 · 11:00',
      );
    });

    test('month abbreviation reflects Hebrew months list', () {
      expect(
        fmtOrgEventDateTime(
          DateTime(2026, 7, 4),
          const TimeOfDay(hour: 20, minute: 30),
          null,
          heMonths,
        ),
        '4 יול 2026 · 20:30',
      );
    });
  });
}
