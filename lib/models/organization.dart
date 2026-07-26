class Organization {
  final String id;
  final String name;
  final String? city;
  final int? cityId;
  final String? cityNameHe;
  final String? cityNameEn;
  final String? cityNameRu;
  final String? address;
  final String? description;
  final String? logoUrl;
  final String? category;
  final List<String> categoryIds;
  final double averageRating;
  final int reviewCount;
  final String? promotionType; // 'top', 'featured', 'highlighted', or null
  final double? distanceKm;

  const Organization({
    required this.id,
    required this.name,
    this.city,
    this.cityId,
    this.cityNameHe,
    this.cityNameEn,
    this.cityNameRu,
    this.address,
    this.description,
    this.logoUrl,
    this.category,
    this.categoryIds = const [],
    required this.averageRating,
    required this.reviewCount,
    this.promotionType,
    this.distanceKm,
  });

  String? localizedCity(String locale) {
    if (cityId != null) {
      return switch (locale) {
        'he' => cityNameHe,
        'ru' => cityNameRu,
        _ => cityNameEn,
      };
    }
    return city;
  }

  factory Organization.fromJson(Map<String, dynamic> json) {
    String? promoType;
    final promo = json['promotion'];
    if (promo is Map) {
      promoType = promo['promotion_type']?.toString();
    } else if (promo is String) {
      promoType = promo;
    }

    return Organization(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      city: json['city']?.toString(),
      cityId: json['city_id'] as int?,
      cityNameHe: json['city_name_he']?.toString(),
      cityNameEn: json['city_name_en']?.toString(),
      cityNameRu: json['city_name_ru']?.toString(),
      address: json['address']?.toString(),
      description: json['description']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      category: json['category']?.toString(),
      categoryIds: _parseOrgCategoryIds(json),
      averageRating: (json['average_rating'] ?? json['rating'] ?? 0).toDouble(),
      reviewCount: (json['review_count'] ?? 0) as int,
      promotionType: promoType,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}

List<String> _parseOrgCategoryIds(Map<String, dynamic> json) {
  final cats = json['categories'];
  if (cats is List && cats.isNotEmpty) {
    return cats
        .whereType<Map<String, dynamic>>()
        .map((c) => c['id']?.toString())
        .whereType<String>()
        .toList();
  }
  final legacy = json['category_id']?.toString();
  return legacy != null ? [legacy] : const [];
}
