import '../models/app_event.dart';
import '../models/org_models.dart';

List<AppEvent> groupEventsBySeries(List<AppEvent> events) {
  final now = DateTime.now();
  final Map<int, AppEvent> bySeriesId = {};
  final List<AppEvent> ungrouped = [];

  for (final e in events) {
    final sid = e.seriesId;
    if (sid == null) {
      ungrouped.add(e);
      continue;
    }
    final existing = bySeriesId[sid];
    if (existing == null) {
      bySeriesId[sid] = e;
    } else {
      final edt = DateTime.tryParse(e.startDatetime ?? '') ?? DateTime(0);
      final exdt = DateTime.tryParse(existing.startDatetime ?? '') ?? DateTime(0);
      final eUp = !edt.isBefore(now);
      final exUp = !exdt.isBefore(now);
      if (eUp && !exUp) {
        bySeriesId[sid] = e;
      } else if (eUp && exUp) {
        if (edt.isBefore(exdt)) bySeriesId[sid] = e;
      } else if (!eUp && !exUp) {
        if (edt.isAfter(exdt)) bySeriesId[sid] = e;
      }
    }
  }

  final result = [...ungrouped, ...bySeriesId.values];
  result.sort((a, b) {
    final adt = DateTime.tryParse(a.startDatetime ?? '') ?? DateTime(0);
    final bdt = DateTime.tryParse(b.startDatetime ?? '') ?? DateTime(0);
    return adt.compareTo(bdt);
  });
  return result;
}

List<OrgEvent> groupOrgEventsBySeries(List<OrgEvent> events) {
  final now = DateTime.now();
  final Map<int, OrgEvent> bySeriesId = {};
  final List<OrgEvent> ungrouped = [];

  for (final e in events) {
    final sid = e.seriesId;
    if (sid == null) {
      ungrouped.add(e);
      continue;
    }
    final existing = bySeriesId[sid];
    if (existing == null) {
      bySeriesId[sid] = e;
    } else {
      final eUp = !e.date.isBefore(now);
      final exUp = !existing.date.isBefore(now);
      if (eUp && !exUp) {
        bySeriesId[sid] = e;
      } else if (eUp && exUp) {
        if (e.date.isBefore(existing.date)) bySeriesId[sid] = e;
      } else if (!eUp && !exUp) {
        if (e.date.isAfter(existing.date)) bySeriesId[sid] = e;
      }
    }
  }

  final result = [...ungrouped, ...bySeriesId.values];
  result.sort((a, b) => a.date.compareTo(b.date));
  return result;
}

List<Map<String, dynamic>> groupRawEventsBySeries(List<Map<String, dynamic>> events) {
  final now = DateTime.now();
  final Map<int, Map<String, dynamic>> bySeriesId = {};
  final List<Map<String, dynamic>> ungrouped = [];

  for (final e in events) {
    final rawSid = e['series_id'];
    if (rawSid == null) {
      ungrouped.add(e);
      continue;
    }
    final sid = rawSid is int ? rawSid : int.tryParse(rawSid.toString());
    if (sid == null) {
      ungrouped.add(e);
      continue;
    }
    final existing = bySeriesId[sid];
    if (existing == null) {
      bySeriesId[sid] = e;
    } else {
      final edt = DateTime.tryParse((e['start_datetime'] ?? '').toString()) ?? DateTime(0);
      final exdt = DateTime.tryParse((existing['start_datetime'] ?? '').toString()) ?? DateTime(0);
      final eUp = !edt.isBefore(now);
      final exUp = !exdt.isBefore(now);
      if (eUp && !exUp) {
        bySeriesId[sid] = e;
      } else if (eUp && exUp) {
        if (edt.isBefore(exdt)) bySeriesId[sid] = e;
      } else if (!eUp && !exUp) {
        if (edt.isAfter(exdt)) bySeriesId[sid] = e;
      }
    }
  }

  final result = [...ungrouped, ...bySeriesId.values];
  result.sort((a, b) {
    final adt = DateTime.tryParse((a['start_datetime'] ?? '').toString()) ?? DateTime(0);
    final bdt = DateTime.tryParse((b['start_datetime'] ?? '').toString()) ?? DateTime(0);
    return adt.compareTo(bdt);
  });
  return result;
}
