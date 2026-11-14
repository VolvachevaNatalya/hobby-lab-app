import '../models/app_class.dart';
import '../screens/filters_screen.dart' show FilterResult;

// Applies client-side filters that can be evaluated from AppClass fields.
//
// Filters handled here:
//   • category   — multi-select, matched against categoryIds / categoryId
//   • distance   — applied only when user changed it from the 10 km default
//   • price      — min/max applied when user changed from the ₪0–500 default;
//                  classes with null price are always included (unknown/free,
//                  matching backend behaviour in /classes/search)
//
// Filters handled server-side (not needed here):
//   • age        — routed through /classes/search with min_age / max_age;
//                  AppClass carries no age data for a client-side fallback.
//   • days       — routed through /classes/search with day_of_week;
//                  AppClass carries no schedule data for a client-side fallback.
List<AppClass> applyClientFilters(List<AppClass> classes, FilterResult f) {
  if (f.isDefault) return classes;
  return classes.where((c) {
    // ── Category ─────────────────────────────────────────────────────────────
    if (f.categoryIds.isNotEmpty &&
        !f.categoryIds.any(
            (id) => c.categoryIds.contains(id) || c.categoryId == id)) {
      return false;
    }

    // ── Distance ─────────────────────────────────────────────────────────────
    // Only filter when the user moved the slider away from the 10 km default.
    // distanceKm is null when classes came from /classes/search (no haversine
    // in that response), in which case the server already applied distance_km.
    if (f.maxDistanceKm != 10.0 &&
        c.distanceKm != null &&
        c.distanceKm! > f.maxDistanceKm) {
      return false;
    }

    // ── Price ─────────────────────────────────────────────────────────────────
    // Classes with null price are included regardless (unknown / free),
    // consistent with backend: OR(price IS NULL, price BETWEEN min AND max).
    if (c.price != null) {
      final minP = f.priceRange.start;
      final maxP = f.priceRange.end;
      if (minP > 0 && c.price! < minP) return false;
      if (maxP < 500 && c.price! > maxP) return false;
    }

    return true;
  }).toList();
}
