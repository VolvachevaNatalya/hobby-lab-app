import 'package:flutter/material.dart';
import '../models/app_category.dart';
import '../models/organization.dart';
import '../models/app_event.dart';

class SavedActivity {
  final String classId;
  final String name;
  final String studio;
  final String category;
  final AppCategory? primaryCategory;
  final double rating;
  final int reviewCount;
  final Color colorStart;
  final Color colorEnd;
  final IconData icon;

  const SavedActivity({
    required this.classId,
    required this.name,
    required this.studio,
    required this.category,
    this.primaryCategory,
    required this.rating,
    required this.reviewCount,
    required this.colorStart,
    required this.colorEnd,
    required this.icon,
  });
}

// ── Classes ───────────────────────────────────────────────────────────────────
final savedActivities = ValueNotifier<List<SavedActivity>>([]);
final favoriteIds = <String, String>{}; // classId → favoriteRecordId

// ── Organizations ─────────────────────────────────────────────────────────────
final savedOrgIds = ValueNotifier<Set<String>>(<String>{});
final savedOrgsList = ValueNotifier<List<Organization>>([]);
final orgFavoriteIds = <String, String>{}; // orgId → favoriteRecordId

// ── Events ────────────────────────────────────────────────────────────────────
final savedEventIds = ValueNotifier<Set<String>>(<String>{});
final savedEventsList = ValueNotifier<List<AppEvent>>([]);
final eventFavoriteIds = <String, String>{}; // eventId → favoriteRecordId

// ── Class helpers ─────────────────────────────────────────────────────────────
bool isSaved(String name) =>
    savedActivities.value.any((a) => a.name == name);

bool isSavedById(String classId) =>
    classId.isNotEmpty && savedActivities.value.any((a) => a.classId == classId);

void toggleSaved(SavedActivity activity) {
  final list = List<SavedActivity>.from(savedActivities.value);
  final idx = list.indexWhere(
      (a) => a.classId == activity.classId || a.name == activity.name);
  if (idx >= 0) {
    list.removeAt(idx);
  } else {
    list.add(activity);
  }
  savedActivities.value = list;
}

// ── Org helpers ───────────────────────────────────────────────────────────────
bool isOrgSaved(String orgId) => orgFavoriteIds.containsKey(orgId);

void addSavedOrg(Organization org, String favoriteId) {
  orgFavoriteIds[org.id] = favoriteId;
  final ids = Set<String>.from(savedOrgIds.value)..add(org.id);
  savedOrgIds.value = ids;
  if (!savedOrgsList.value.any((o) => o.id == org.id)) {
    savedOrgsList.value = [...savedOrgsList.value, org];
  }
}

void removeSavedOrg(String orgId) {
  orgFavoriteIds.remove(orgId);
  final ids = Set<String>.from(savedOrgIds.value)..remove(orgId);
  savedOrgIds.value = ids;
  savedOrgsList.value =
      savedOrgsList.value.where((o) => o.id != orgId).toList();
}

// ── Event helpers ─────────────────────────────────────────────────────────────
bool isEventSaved(String eventId) => eventFavoriteIds.containsKey(eventId);

void addSavedEvent(AppEvent event, String favoriteId) {
  eventFavoriteIds[event.id] = favoriteId;
  final ids = Set<String>.from(savedEventIds.value)..add(event.id);
  savedEventIds.value = ids;
  if (!savedEventsList.value.any((e) => e.id == event.id)) {
    savedEventsList.value = [...savedEventsList.value, event];
  }
}

void removeSavedEvent(String eventId) {
  eventFavoriteIds.remove(eventId);
  final ids = Set<String>.from(savedEventIds.value)..remove(eventId);
  savedEventIds.value = ids;
  savedEventsList.value =
      savedEventsList.value.where((e) => e.id != eventId).toList();
}
