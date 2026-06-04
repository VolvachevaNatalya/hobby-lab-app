class Activity {
  final String id;
  final String name;
  final String studio;
  final String category;
  final double rating;
  final int reviewCount;

  const Activity({
    required this.id,
    required this.name,
    required this.studio,
    required this.category,
    required this.rating,
    required this.reviewCount,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: (json['id'] ?? '').toString(),
      name: (json['title'] ?? json['name'] ?? '').toString(),
      studio: (json['organization_name'] ?? json['studio'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      rating: (json['average_rating'] ?? json['rating'] ?? 0).toDouble(),
      reviewCount: (json['review_count'] ?? json['reviewCount'] ?? 0) as int,
    );
  }
}
