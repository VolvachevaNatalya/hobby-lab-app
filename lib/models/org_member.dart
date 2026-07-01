class OrgMember {
  final int userId;
  final String name;
  final String email;
  final String role;
  final DateTime? joinedAt;

  const OrgMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.joinedAt,
  });

  factory OrgMember.fromJson(Map<String, dynamic> json) => OrgMember(
        userId: json['user_id'] as int,
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? 'member').toString(),
        joinedAt: json['joined_at'] != null
            ? DateTime.tryParse(json['joined_at'].toString())
            : null,
      );
}
