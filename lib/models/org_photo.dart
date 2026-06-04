class OrgPhoto {
  final String id;
  final String photoUrl;

  const OrgPhoto({required this.id, required this.photoUrl});

  factory OrgPhoto.fromJson(Map<String, dynamic> json) {
    return OrgPhoto(
      id: (json['id'] ?? '').toString(),
      photoUrl: (json['photo_url'] ?? '').toString(),
    );
  }
}
