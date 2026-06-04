class Favorite {
  final String id;
  final String entityId;
  final String entityType;

  const Favorite({
    required this.id,
    required this.entityId,
    required this.entityType,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: (json['id'] ?? '').toString(),
      entityId: (json['entity_id'] ?? '').toString(),
      entityType: (json['entity_type'] ?? 'class').toString(),
    );
  }
}
