class AppCategory {
  final String id;
  final String name;

  const AppCategory({required this.id, required this.name});

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    return AppCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}
