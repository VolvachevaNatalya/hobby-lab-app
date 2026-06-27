// Models for the organization invite / join-request system.

class OrgInviteCode {
  final int id;
  final int organizationId;
  final String code;
  final String defaultRole;
  final bool requiresApproval;
  final bool isActive;
  final DateTime? expiresAt;
  final int? createdByUserId;
  final DateTime createdAt;

  const OrgInviteCode({
    required this.id,
    required this.organizationId,
    required this.code,
    required this.defaultRole,
    required this.requiresApproval,
    required this.isActive,
    this.expiresAt,
    this.createdByUserId,
    required this.createdAt,
  });

  factory OrgInviteCode.fromJson(Map<String, dynamic> json) {
    return OrgInviteCode(
      id: json['id'] as int,
      organizationId: json['organization_id'] as int,
      code: (json['code'] ?? '').toString(),
      defaultRole: (json['default_role'] ?? 'member').toString(),
      requiresApproval: json['requires_approval'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      createdByUserId: json['created_by_user_id'] as int?,
      createdAt: DateTime.tryParse(
              (json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class OrgJoinRequest {
  final int id;
  final int organizationId;
  final int userId;
  final String userName;
  final String userEmail;
  final int? inviteCodeId;
  final DateTime createdAt;

  const OrgJoinRequest({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.inviteCodeId,
    required this.createdAt,
  });

  factory OrgJoinRequest.fromJson(Map<String, dynamic> json) {
    return OrgJoinRequest(
      id: json['id'] as int,
      organizationId: json['organization_id'] as int,
      userId: json['user_id'] as int,
      userName: (json['user_name'] ?? '').toString(),
      userEmail: (json['user_email'] ?? '').toString(),
      inviteCodeId: json['invite_code_id'] as int?,
      createdAt: DateTime.tryParse(
              (json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

// Returned by GET /invite-codes/resolve
class InviteCodeResolveResult {
  final int organizationId;
  final String organizationName;
  final String defaultRole;
  final bool requiresApproval;

  const InviteCodeResolveResult({
    required this.organizationId,
    required this.organizationName,
    required this.defaultRole,
    required this.requiresApproval,
  });

  factory InviteCodeResolveResult.fromJson(Map<String, dynamic> json) {
    return InviteCodeResolveResult(
      organizationId: json['organization_id'] as int,
      organizationName: (json['organization_name'] ?? '').toString(),
      defaultRole: (json['default_role'] ?? 'member').toString(),
      requiresApproval: json['requires_approval'] as bool? ?? true,
    );
  }
}

// Returned by POST /organizations/{org_id}/join-requests
class JoinResult {
  final bool requiresApproval;
  final int? joinRequestId;
  final String? role;

  const JoinResult({
    required this.requiresApproval,
    this.joinRequestId,
    this.role,
  });

  factory JoinResult.fromJson(Map<String, dynamic> json) {
    return JoinResult(
      requiresApproval: json['requires_approval'] as bool? ?? true,
      joinRequestId: json['join_request_id'] as int?,
      role: json['role']?.toString(),
    );
  }
}
