class AppCity {
  final int id;
  final String nameHe;
  final String nameEn;
  final String nameRu;

  const AppCity({
    required this.id,
    required this.nameHe,
    required this.nameEn,
    required this.nameRu,
  });

  factory AppCity.fromJson(Map<String, dynamic> json) => AppCity(
        id: json['id'] as int,
        nameHe: (json['name_he'] ?? '').toString(),
        nameEn: (json['name_en'] ?? '').toString(),
        nameRu: (json['name_ru'] ?? '').toString(),
      );

  String displayName(String locale) => switch (locale) {
        'he' => nameHe,
        'ru' => nameRu,
        _ => nameEn,
      };
}
