class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
  });

  String get initials {
    final words = fullName.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length.clamp(0, 2)).toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['name'] ?? '').toString(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}
