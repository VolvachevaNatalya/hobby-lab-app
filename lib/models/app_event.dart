import 'event_recurrence.dart';

class AppEvent {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String? categoryId;
  final List<String> categoryIds;
  final String? startDatetime;
  final String? endDatetime;
  final String? address;
  final String? city;
  final int? cityId;
  final String? cityNameHe;
  final String? cityNameEn;
  final String? cityNameRu;
  final int? organizationId;
  final int? minAge;
  final int? maxAge;
  final int? capacity;
  final double? distanceKm;
  final bool isNationwide;
  final double? price;
  final String? priceComment;
  final int? seriesId;
  final int? occurrenceIndex;
  final String? originalStartDatetime;
  final EventRecurrence? recurrence;
  final String? imageUrl;
  final List<String> categoryNames;

  const AppEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.categoryId,
    this.categoryIds = const [],
    this.startDatetime,
    this.endDatetime,
    this.address,
    this.city,
    this.cityId,
    this.cityNameHe,
    this.cityNameEn,
    this.cityNameRu,
    this.organizationId,
    this.minAge,
    this.maxAge,
    this.capacity,
    this.distanceKm,
    this.isNationwide = false,
    this.price,
    this.priceComment,
    this.seriesId,
    this.occurrenceIndex,
    this.originalStartDatetime,
    this.recurrence,
    this.imageUrl,
    this.categoryNames = const [],
  });

  factory AppEvent.fromJson(Map<String, dynamic> json) => AppEvent(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? json['name'] ?? '').toString(),
    subtitle: (json['description'] ?? json['subtitle'] ?? '').toString(),
    badge: (json['badge'] ?? json['status'] ?? json['type'] ?? 'NEW')
        .toString()
        .toUpperCase(),
    categoryId: json['category_id']?.toString(),
    categoryIds: _parseCategoryIds(json),
    startDatetime: json['start_datetime']?.toString(),
    endDatetime: json['end_datetime']?.toString(),
    address: json['address']?.toString(),
    city: json['city']?.toString(),
    cityId: json['city_id'] as int?,
    cityNameHe: json['city_name_he']?.toString(),
    cityNameEn: json['city_name_en']?.toString(),
    cityNameRu: json['city_name_ru']?.toString(),
    organizationId: json['organization_id'] as int?,
    minAge: json['min_age'] as int?,
    maxAge: json['max_age'] as int?,
    capacity: json['capacity'] as int?,
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
    isNationwide: json['is_nationwide'] as bool? ?? false,
    price: (json['price'] as num?)?.toDouble(),
    priceComment: json['price_comment']?.toString(),
    seriesId: json['series_id'] as int?,
    occurrenceIndex: json['occurrence_index'] as int?,
    originalStartDatetime: json['original_start_datetime']?.toString(),
    recurrence: json['recurrence'] != null
        ? EventRecurrence.fromJson(json['recurrence'] as Map<String, dynamic>)
        : null,
    imageUrl: json['image_url']?.toString(),
    categoryNames: _parseCategoryNames(json),
  );
}

List<String> _parseCategoryNames(Map<String, dynamic> json) {
  final cats = json['categories'];
  if (cats is List && cats.isNotEmpty) {
    return cats
        .map((c) => (c as Map<String, dynamic>)['name']?.toString())
        .whereType<String>()
        .toList();
  }
  return const [];
}

List<String> _parseCategoryIds(Map<String, dynamic> json) {
  final cats = json['categories'];
  if (cats is List && cats.isNotEmpty) {
    return cats
        .map((c) => (c as Map<String, dynamic>)['id']?.toString())
        .whereType<String>()
        .toList();
  }
  final legacy = json['category_id']?.toString();
  return legacy != null ? [legacy] : const [];
}
