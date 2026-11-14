class AppCategory {
  final String id;
  final String name;
  final String? nameEn;
  final String? nameRu;
  final String? nameHe;
  final String? iconUrl;

  const AppCategory({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameRu,
    this.nameHe,
    this.iconUrl,
  });

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    return AppCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      nameEn: json['name_en']?.toString(),
      nameRu: json['name_ru']?.toString(),
      nameHe: json['name_he']?.toString(),
      iconUrl: json['icon_url']?.toString(),
    );
  }

  String localizedName(String locale) {
    if (locale == 'he' && nameHe != null && nameHe!.isNotEmpty) return nameHe!;
    if (locale == 'ru' && nameRu != null && nameRu!.isNotEmpty) return nameRu!;
    if (nameEn != null && nameEn!.isNotEmpty) return nameEn!;
    return name;
  }

  // Stable English identifier used for icon/color mapping.
  String get stableNameEn => nameEn ?? name;
}
