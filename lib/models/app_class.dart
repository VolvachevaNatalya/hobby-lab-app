class AppClass {
  final String id;
  final String title;
  final String organizationName;
  final String organizationId;
  final String categoryId;
  final String category;
  final double averageRating;
  final int reviewCount;
  final String description;
  final String? address;
  final String? website;
  final double? distanceKm;

  const AppClass({
    required this.id,
    required this.title,
    required this.organizationName,
    required this.organizationId,
    required this.categoryId,
    required this.category,
    required this.averageRating,
    required this.reviewCount,
    required this.description,
    this.address,
    this.website,
    this.distanceKm,
  });

  factory AppClass.fromJson(Map<String, dynamic> json) {
    return AppClass(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      organizationName:
          (json['organization_name'] ?? json['studio'] ?? '').toString(),
      organizationId: (json['organization_id'] ?? '').toString(),
      categoryId: (json['category_id'] ?? '').toString(),
      category: (json['category'] ?? json['category_name'] ?? '').toString(),
      averageRating:
          (json['average_rating'] ?? json['rating'] ?? 0).toDouble(),
      reviewCount: (json['review_count'] ?? json['reviewCount'] ?? 0) as int,
      description: (json['description'] ?? '').toString(),
      address: json['address']?.toString(),
      website: json['website']?.toString(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}
