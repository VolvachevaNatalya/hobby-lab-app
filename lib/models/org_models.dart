import 'package:flutter/material.dart';
import 'app_category.dart';
import 'event_recurrence.dart';

// ─── Data models ─────────────────────────────────────────────────────────────

class OrgScheduleSlot {
  final String day;
  final TimeOfDay start;
  final TimeOfDay end;

  const OrgScheduleSlot({
    required this.day,
    required this.start,
    required this.end,
  });
}

class OrgGroup {
  String name;
  int minAge;
  int maxAge;
  int capacity;
  double price;
  List<OrgScheduleSlot> schedule;

  OrgGroup({
    required this.name,
    required this.minAge,
    required this.maxAge,
    required this.capacity,
    required this.price,
    this.schedule = const [],
  });
}

class OrgClass {
  final String id;
  String name;
  String category;
  List<String> categoryIds;
  List<AppCategory> categoryList;
  String description;
  List<OrgGroup> groups;

  OrgClass({
    required this.id,
    required this.name,
    this.category = '',
    this.categoryIds = const [],
    this.categoryList = const [],
    this.description = '',
    this.groups = const [],
  });
}

class OrgEvent {
  final String id;
  String name;
  String category;
  List<String> categoryIds;
  List<AppCategory> categoryList;
  String description;
  DateTime date;
  TimeOfDay time;
  String location;
  int? cityId;
  String? cityNameHe;
  String? cityNameEn;
  String? cityNameRu;
  int minAge;
  int maxAge;
  int capacity;
  double price;
  String? priceComment;
  bool isNationwide;
  DateTime? endDateTime;
  int? seriesId;
  int? occurrenceIndex;
  EventRecurrence? recurrence;
  String? imageUrl;

  OrgEvent({
    required this.id,
    required this.name,
    required this.category,
    this.categoryIds = const [],
    this.categoryList = const [],
    this.description = '',
    required this.date,
    required this.time,
    this.endDateTime,
    this.location = '',
    this.cityId,
    this.cityNameHe,
    this.cityNameEn,
    this.cityNameRu,
    this.minAge = 0,
    this.maxAge = 99,
    this.capacity = 20,
    this.price = 0,
    this.priceComment,
    this.isNationwide = false,
    this.seriesId,
    this.occurrenceIndex,
    this.recurrence,
    this.imageUrl,
  });
}

// ─── Category helpers (pass AppCategory.stableNameEn, not localized name) ────

Color catColorStart(String cat) => switch (cat) {
  'Sport' => const Color(0xFF059669),
  'Art' => const Color(0xFFFF9100),
  'Music' => const Color(0xFFEC4899),
  'Education' => const Color(0xFF3B82F6),
  'Theater' => const Color(0xFF9333EA),
  'Master Class' => const Color(0xFFFFD700),
  _ => const Color(0xFF7C3AED),
};

Color catColorEnd(String cat) => switch (cat) {
  'Sport' => const Color(0xFF0EA5E9),
  'Art' => const Color(0xFFEC4899),
  'Music' => const Color(0xFF7C3AED),
  'Education' => const Color(0xFF7C3AED),
  'Theater' => const Color(0xFFEC4899),
  'Master Class' => const Color(0xFFFF9100),
  _ => const Color(0xFFEC4899),
};

IconData catIcon(String cat) => switch (cat) {
  'Sport' => Icons.sports_soccer_rounded,
  'Art' => Icons.brush_rounded,
  'Music' => Icons.music_note_rounded,
  'Education' => Icons.school_rounded,
  'Theater' => Icons.theater_comedy_rounded,
  'Master Class' => Icons.star_rounded,
  _ => Icons.category_rounded,
};

String fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String fmtDate(DateTime d) {
  const months = [
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
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String genId() => DateTime.now().millisecondsSinceEpoch.toString();

int dayToInt(String day) => switch (day) {
  'Sun' => 0,
  'Mon' => 1,
  'Tue' => 2,
  'Wed' => 3,
  'Thu' => 4,
  'Fri' => 5,
  'Sat' => 6,
  _ => 0,
};

String fmtApiTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

// ─── Dark time/date picker theme ──────────────────────────────────────────────

ThemeData darkPickerTheme(BuildContext context) {
  return ThemeData.dark().copyWith(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7C3AED),
      onSurface: Color(0xFFF1F5F9),
      surface: Color(0xFF1E2535),
    ),
    timePickerTheme: const TimePickerThemeData(
      backgroundColor: Color(0xFF1E2535),
      hourMinuteColor: Color(0xFF252D3D),
      dialBackgroundColor: Color(0xFF252D3D),
      dialHandColor: Color(0xFF7C3AED),
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: Color(0xFF1E2535),
      headerBackgroundColor: Color(0xFF7C3AED),
      dayBackgroundColor: WidgetStatePropertyAll(Colors.transparent),
    ),
  );
}
