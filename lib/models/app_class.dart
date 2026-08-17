import 'app_category.dart';

class AppClass {
  final String id;
  final String title;
  final String organizationName;
  final String organizationId;
  final String categoryId;
  final String category;
  final List<String> categoryIds;
  final AppCategory? primaryCategory;
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
    this.categoryIds = const [],
    this.primaryCategory,
    required this.averageRating,
    required this.reviewCount,
    required this.description,
    this.address,
    this.website,
    this.distanceKm,
  });

  factory AppClass.fromJson(Map<String, dynamic> json) {
    final cats = json['categories'];
    List<String> categoryIds;
    String categoryId;
    String category;
    AppCategory? primaryCategory;

    if (cats is List && cats.isNotEmpty) {
      final firstCat = cats.first as Map<String, dynamic>;
      primaryCategory = AppCategory.fromJson(firstCat);
      categoryIds = cats
          .map((c) => (c as Map<String, dynamic>)['id']?.toString())
          .whereType<String>()
          .toList();
      categoryId = categoryIds.first;
      category = primaryCategory.stableNameEn;
    } else {
      categoryId = (json['category_id'] ?? '').toString();
      categoryIds = categoryId.isNotEmpty ? [categoryId] : const [];
      category = (json['category'] ?? json['category_name'] ?? '').toString();
      primaryCategory = null;
    }

    return AppClass(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      organizationName:
          (json['organization_name'] ?? json['studio'] ?? '').toString(),
      organizationId: (json['organization_id'] ?? '').toString(),
      categoryId: categoryId,
      category: category,
      categoryIds: categoryIds,
      primaryCategory: primaryCategory,
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
