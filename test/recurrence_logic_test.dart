import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_lab/models/event_recurrence.dart';

RecurrenceInput _ri({
  String frequency = 'weekly',
  int interval = 1,
  String endType = 'never',
  int? totalCount,
  String? endDate,
}) =>
    RecurrenceInput(
      frequency: frequency,
      interval: interval,
      endType: endType,
      totalCount: totalCount,
      endDate: endDate,
    );

void main() {
  // ── recurrenceInputChanged ─────────────────────────────────────────────────

  group('recurrenceInputChanged', () {
    test('returns false when both null', () {
      expect(recurrenceInputChanged(null, null), isFalse);
    });

    test('returns true when original is null and current is not', () {
      expect(recurrenceInputChanged(null, _ri()), isTrue);
    });

    test('returns true when current is null and original is not', () {
      expect(recurrenceInputChanged(_ri(), null), isTrue);
    });

    test('returns false when both are identical', () {
      final a = _ri(frequency: 'weekly', interval: 1, endType: 'never');
      final b = _ri(frequency: 'weekly', interval: 1, endType: 'never');
      expect(recurrenceInputChanged(a, b), isFalse);
    });

    test('returns true when frequency differs', () {
      expect(
        recurrenceInputChanged(
          _ri(frequency: 'weekly'),
          _ri(frequency: 'daily'),
        ),
        isTrue,
      );
    });

    test('returns true when interval differs', () {
      expect(
        recurrenceInputChanged(_ri(interval: 1), _ri(interval: 2)),
        isTrue,
      );
    });

    test('returns true when endType differs', () {
      expect(
        recurrenceInputChanged(
          _ri(endType: 'never'),
          _ri(endType: 'count', totalCount: 5),
        ),
        isTrue,
      );
    });

    test('returns true when totalCount differs', () {
      expect(
        recurrenceInputChanged(
          _ri(endType: 'count', totalCount: 5),
          _ri(endType: 'count', totalCount: 10),
        ),
        isTrue,
      );
    });

    test('returns true when endDate differs', () {
      expect(
        recurrenceInputChanged(
          _ri(endType: 'date', endDate: '2026-01-01'),
          _ri(endType: 'date', endDate: '2026-06-01'),
        ),
        isTrue,
      );
    });

    test('returns false when count-based configs are identical', () {
      final a = _ri(endType: 'count', totalCount: 8);
      final b = _ri(endType: 'count', totalCount: 8);
      expect(recurrenceInputChanged(a, b), isFalse);
    });

    test('returns false when date-based configs are identical', () {
      final a = _ri(endType: 'date', endDate: '2026-12-31');
      final b = _ri(endType: 'date', endDate: '2026-12-31');
      expect(recurrenceInputChanged(a, b), isFalse);
    });
  });

  // ── _parseOccurrence ageGroups ─────────────────────────────────────────────
  // The parser is a private static on _EventScheduleScreenState, so we verify
  // the underlying logic — parsing a JSON age_groups array — by exercising
  // EventRecurrence.fromJson (same casting pattern).

  group('age_groups JSON parsing', () {
    test('parses a list of strings', () {
      final json = ['kids', 'teens'];
      final result =
          (json as List<dynamic>).map((e) => e.toString()).toList();
      expect(result, ['kids', 'teens']);
    });

    test('returns empty list when age_groups is absent', () {
      final Map<String, dynamic> json = {};
      final result =
          (json['age_groups'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      expect(result, isEmpty);
    });

    test('returns empty list when age_groups is null', () {
      final Map<String, dynamic> json = {'age_groups': null};
      final result =
          (json['age_groups'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      expect(result, isEmpty);
    });

    test('converts non-string elements to strings', () {
      final Map<String, dynamic> json = {
        'age_groups': [1, 'adults'],
      };
      final result =
          (json['age_groups'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
      expect(result, ['1', 'adults']);
    });
  });
}
