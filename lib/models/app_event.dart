class AppEvent {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String? categoryId;
  final String? startDatetime;
  final String? endDatetime;
  final String? address;
  final String? city;
  final int? organizationId;
  final int? minAge;
  final int? maxAge;
  final int? capacity;
  final double? distanceKm;
  final bool isNationwide;
  final double? price;
  final String? priceComment;

  const AppEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.categoryId,
    this.startDatetime,
    this.endDatetime,
    this.address,
    this.city,
    this.organizationId,
    this.minAge,
    this.maxAge,
    this.capacity,
    this.distanceKm,
    this.isNationwide = false,
    this.price,
    this.priceComment,
  });

  factory AppEvent.fromJson(Map<String, dynamic> json) {
    return AppEvent(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      subtitle: (json['description'] ?? json['subtitle'] ?? '').toString(),
      badge: (json['badge'] ?? json['status'] ?? json['type'] ?? 'NEW').toString().toUpperCase(),
      categoryId: json['category_id']?.toString(),
      startDatetime: json['start_datetime']?.toString(),
      endDatetime: json['end_datetime']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      organizationId: json['organization_id'] as int?,
      minAge: json['min_age'] as int?,
      maxAge: json['max_age'] as int?,
      capacity: json['capacity'] as int?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      isNationwide: json['is_nationwide'] as bool? ?? false,
      price: (json['price'] as num?)?.toDouble(),
      priceComment: json['price_comment']?.toString(),
    );
  }
}
