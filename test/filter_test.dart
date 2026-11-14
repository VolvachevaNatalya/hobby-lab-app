import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_lab/models/app_class.dart';
import 'package:hobby_lab/models/app_category.dart';
import 'package:hobby_lab/screens/filters_screen.dart' show FilterResult;
import 'package:hobby_lab/utils/class_filter.dart';
import 'package:hobby_lab/models/org_models.dart' show dayToInt;

// ─── Helpers ──────────────────────────────────────────────────────────────────

AppClass _cls({
  String id = '1',
  String categoryId = 'cat1',
  List<String> categoryIds = const ['cat1'],
  double? distanceKm,
  double? price,
  String? priceType,
}) {
  return AppClass(
    id: id,
    title: 'Test Class',
    organizationName: 'Test Org',
    organizationId: 'org1',
    categoryId: categoryId,
    category: 'Test',
    categoryIds: categoryIds,
    primaryCategory: AppCategory(id: categoryId, name: 'Test'),
    averageRating: 0,
    reviewCount: 0,
    description: '',
    distanceKm: distanceKm,
    price: price,
    priceType: priceType,
  );
}

// ─── FilterResult ─────────────────────────────────────────────────────────────

void main() {
  group('FilterResult.isDefault / activeCount', () {
    test('default constructor is default', () {
      expect(const FilterResult().isDefault, isTrue);
      expect(const FilterResult().activeCount, 0);
    });

    test('non-default age range counts as 1', () {
      final f = FilterResult(ageRange: const RangeValues(5, 10));
      expect(f.activeCount, 1);
      expect(f.isDefault, isFalse);
    });

    test('non-default price range counts as 1', () {
      final f = FilterResult(priceRange: const RangeValues(50, 300));
      expect(f.activeCount, 1);
      expect(f.isDefault, isFalse);
    });

    test('non-default distance counts as 1', () {
      final f = FilterResult(maxDistanceKm: 5);
      expect(f.activeCount, 1);
      expect(f.isDefault, isFalse);
    });

    test('each category ID counts separately', () {
      final f = FilterResult(categoryIds: {'cat1', 'cat2'});
      expect(f.activeCount, 2);
    });

    test('each day counts separately', () {
      final f = FilterResult(days: {'Mon', 'Wed', 'Fri'});
      expect(f.activeCount, 3);
    });

    test('all filters combined', () {
      final f = FilterResult(
        ageRange: const RangeValues(5, 10),
        priceRange: const RangeValues(50, 200),
        maxDistanceKm: 7,
        categoryIds: {'cat1'},
        days: {'Mon', 'Tue'},
      );
      expect(f.activeCount, 6); // 1+1+1+1+2
      expect(f.isDefault, isFalse);
    });

    test('distance at default 10 km does not count', () {
      final f = FilterResult(maxDistanceKm: 10);
      expect(f.activeCount, 0);
      expect(f.isDefault, isTrue);
    });
  });

  // ─── day-to-int mapping ──────────────────────────────────────────────────────

  group('dayToInt encoding (Sun=0, Mon=1, …, Sat=6)', () {
    test('maps Sun→0 through Sat→6', () {
      expect(dayToInt('Sun'), 0);
      expect(dayToInt('Mon'), 1);
      expect(dayToInt('Tue'), 2);
      expect(dayToInt('Wed'), 3);
      expect(dayToInt('Thu'), 4);
      expect(dayToInt('Fri'), 5);
      expect(dayToInt('Sat'), 6);
    });

    test('unknown key falls back to 0', () {
      expect(dayToInt('???'), 0);
    });
  });

  // ─── applyClientFilters ───────────────────────────────────────────────────────

  group('applyClientFilters — category', () {
    final c1 = _cls(id: '1', categoryId: 'cat1', categoryIds: ['cat1']);
    final c2 = _cls(id: '2', categoryId: 'cat2', categoryIds: ['cat2']);
    final c3 = _cls(id: '3', categoryId: 'cat3', categoryIds: ['cat1', 'cat3']);

    test('no category filter returns all', () {
      final result = applyClientFilters([c1, c2, c3], const FilterResult());
      expect(result, hasLength(3));
    });

    test('single category keeps matching classes', () {
      final f = FilterResult(categoryIds: {'cat1'});
      final result = applyClientFilters([c1, c2, c3], f);
      expect(result.map((c) => c.id), containsAll(['1', '3']));
      expect(result.map((c) => c.id), isNot(contains('2')));
    });

    test('multiple categories keeps union', () {
      final f = FilterResult(categoryIds: {'cat1', 'cat2'});
      final result = applyClientFilters([c1, c2, c3], f);
      expect(result, hasLength(3));
    });

    test('class whose categoryId (not in categoryIds list) still matches', () {
      final orphan = _cls(id: '4', categoryId: 'cat9', categoryIds: []);
      final f = FilterResult(categoryIds: {'cat9'});
      final result = applyClientFilters([orphan], f);
      expect(result, hasLength(1));
    });
  });

  group('applyClientFilters — distance', () {
    final near = _cls(id: 'near', distanceKm: 3);
    final borderline = _cls(id: 'border', distanceKm: 7);
    final far = _cls(id: 'far', distanceKm: 12);
    final noCoord = _cls(id: 'nocoord'); // distanceKm == null

    test('default distance (10 km) does not filter anything', () {
      final result = applyClientFilters([near, borderline, far, noCoord], const FilterResult());
      expect(result, hasLength(4));
    });

    test('filter at 7 km excludes class at 12 km, keeps 3 km and null', () {
      final f = FilterResult(maxDistanceKm: 7);
      final result = applyClientFilters([near, borderline, far, noCoord], f);
      expect(result.map((c) => c.id), containsAll(['near', 'border', 'nocoord']));
      expect(result.map((c) => c.id), isNot(contains('far')));
    });

    test('class with null distanceKm passes distance filter always', () {
      final f = FilterResult(maxDistanceKm: 1);
      final result = applyClientFilters([noCoord], f);
      expect(result, hasLength(1));
    });
  });

  group('applyClientFilters — price', () {
    final free = _cls(id: 'free', price: 0);
    final cheap = _cls(id: 'cheap', price: 80);
    final mid = _cls(id: 'mid', price: 200);
    final expensive = _cls(id: 'exp', price: 450);
    final noPrice = _cls(id: 'noprice'); // price == null

    test('default price range (0–500) does not filter anything', () {
      final result = applyClientFilters([free, cheap, mid, expensive, noPrice], const FilterResult());
      expect(result, hasLength(5));
    });

    test('max price filter excludes classes above cap', () {
      final f = FilterResult(priceRange: const RangeValues(0, 300));
      final result = applyClientFilters([free, cheap, mid, expensive, noPrice], f);
      expect(result.map((c) => c.id), containsAll(['free', 'cheap', 'mid', 'noprice']));
      expect(result.map((c) => c.id), isNot(contains('exp')));
    });

    test('min price filter excludes classes below floor', () {
      final f = FilterResult(priceRange: const RangeValues(100, 500));
      final result = applyClientFilters([free, cheap, mid, expensive, noPrice], f);
      expect(result.map((c) => c.id), containsAll(['mid', 'exp', 'noprice']));
      expect(result.map((c) => c.id), isNot(contains('free')));
      expect(result.map((c) => c.id), isNot(contains('cheap')));
    });

    test('class with null price always passes price filter', () {
      final f = FilterResult(priceRange: const RangeValues(100, 200));
      final result = applyClientFilters([noPrice], f);
      expect(result, hasLength(1));
    });

    test('combined min+max range', () {
      final f = FilterResult(priceRange: const RangeValues(50, 250));
      final result = applyClientFilters([free, cheap, mid, expensive, noPrice], f);
      expect(result.map((c) => c.id), containsAll(['cheap', 'mid', 'noprice']));
      expect(result.map((c) => c.id), isNot(contains('free')));
      expect(result.map((c) => c.id), isNot(contains('exp')));
    });
  });

  group('applyClientFilters — combined filters', () {
    final c1 = _cls(id: '1', categoryId: 'cat1', categoryIds: ['cat1'], price: 150, distanceKm: 4);
    final c2 = _cls(id: '2', categoryId: 'cat2', categoryIds: ['cat2'], price: 400, distanceKm: 2);
    final c3 = _cls(id: '3', categoryId: 'cat1', categoryIds: ['cat1'], price: 60, distanceKm: 15);

    test('category + price + distance combined', () {
      final f = FilterResult(
        categoryIds: {'cat1'},
        priceRange: const RangeValues(0, 200),
        maxDistanceKm: 8,
      );
      final result = applyClientFilters([c1, c2, c3], f);
      // c1: cat1 ✓, price 150 ≤ 200 ✓, dist 4 ≤ 8 ✓ → included
      // c2: cat2 ✗ → excluded
      // c3: cat1 ✓, price 60 ≤ 200 ✓, dist 15 > 8 ✗ → excluded
      expect(result.map((c) => c.id), equals(['1']));
    });
  });

  // ─── FilterResult — age routing signals ──────────────────────────────────────
  // These properties determine whether _buildClassesFuture routes through
  // /classes/search with min_age / max_age or falls back to /classes/.

  group('FilterResult — age routing signals', () {
    test('default age range (3–120) leaves filter as default', () {
      final f = FilterResult(ageRange: const RangeValues(3, 120));
      expect(f.isDefault, isTrue);
      expect(f.activeCount, 0);
    });

    test('changed upper bound makes filter non-default', () {
      final f = FilterResult(ageRange: const RangeValues(3, 10));
      expect(f.isDefault, isFalse);
      expect(f.activeCount, 1);
    });

    test('changed lower bound makes filter non-default', () {
      final f = FilterResult(ageRange: const RangeValues(5, 120));
      expect(f.isDefault, isFalse);
      expect(f.activeCount, 1);
    });

    test('both bounds changed counts as one active filter', () {
      final f = FilterResult(ageRange: const RangeValues(5, 12));
      expect(f.activeCount, 1);
    });

    test('age range rounds to correct int params', () {
      // The slider returns doubles; .round() converts to int for the API.
      final f = FilterResult(ageRange: const RangeValues(4.6, 11.3));
      expect(f.ageRange.start.round(), 5);
      expect(f.ageRange.end.round(), 11);
    });

    test('age + days combined counts correctly', () {
      final f = FilterResult(
        ageRange: const RangeValues(5, 10),
        days: {'Mon', 'Wed'},
      );
      expect(f.activeCount, 3); // 1 (age) + 2 (days)
      expect(f.isDefault, isFalse);
    });

    test('age + price + category combined counts correctly', () {
      final f = FilterResult(
        ageRange: const RangeValues(4, 14),
        priceRange: const RangeValues(0, 200),
        categoryIds: {'cat1', 'cat2'},
      );
      expect(f.activeCount, 4); // 1 (age) + 1 (price) + 2 (categories)
    });

    test('all five filter types active counts correctly', () {
      final f = FilterResult(
        ageRange: const RangeValues(5, 10),
        priceRange: const RangeValues(50, 300),
        maxDistanceKm: 5,
        categoryIds: {'catA'},
        days: {'Mon', 'Fri'},
      );
      expect(f.activeCount, 6); // 1+1+1+1+2
    });
  });

  // ─── AppClass.fromJson parses price fields ────────────────────────────────────

  group('AppClass.fromJson — price fields', () {
    test('parses price and price_type', () {
      final cls = AppClass.fromJson({
        'id': '10',
        'name': 'Dance',
        'organization_id': '1',
        'category_id': '2',
        'average_rating': 4.5,
        'review_count': 10,
        'price': 150.0,
        'price_type': 'monthly',
      });
      expect(cls.price, 150.0);
      expect(cls.priceType, 'monthly');
    });

    test('price is null when absent', () {
      final cls = AppClass.fromJson({'id': '1', 'name': 'X'});
      expect(cls.price, isNull);
      expect(cls.priceType, isNull);
    });

    test('price parses integer JSON value as double', () {
      final cls = AppClass.fromJson({'id': '2', 'name': 'Y', 'price': 200});
      expect(cls.price, 200.0);
    });
  });
}
