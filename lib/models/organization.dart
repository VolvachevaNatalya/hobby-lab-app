class Organization {
  final String id;
  final String name;
  final String? city;
  final String? address;
  final String? description;
  final String? logoUrl;
  final String? category;
  final double averageRating;
  final int reviewCount;
  final String? promotionType; // 'top', 'featured', 'highlighted', or null
  final double? distanceKm;

  const Organization({
    required this.id,
    required this.name,
    this.city,
    this.address,
    this.description,
    this.logoUrl,
    this.category,
    required this.averageRating,
    required this.reviewCount,
    this.promotionType,
    this.distanceKm,
  });

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
      address: json['address']?.toString(),
      description: json['description']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      category: json['category']?.toString(),
      averageRating: (json['average_rating'] ?? json['rating'] ?? 0).toDouble(),
      reviewCount: (json['review_count'] ?? 0) as int,
      promotionType: promoType,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}
