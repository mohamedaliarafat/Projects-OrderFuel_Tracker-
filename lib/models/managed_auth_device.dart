class ManagedDeviceUser {
  const ManagedDeviceUser({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
    required this.phone,
    required this.company,
  });

  final String id;
  final String name;
  final String email;
  final String username;
  final String role;
  final String phone;
  final String company;

  String get displayLabel {
    if (name.trim().isNotEmpty) return name.trim();
    if (username.trim().isNotEmpty) return username.trim();
    return email.trim();
  }

  factory ManagedDeviceUser.fromJson(Map<String, dynamic> json) {
    return ManagedDeviceUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      company: (json['company'] ?? '').toString(),
    );
  }
}

class ManagedAuthDevice {
  const ManagedAuthDevice({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.userAgent,
    required this.ipAddress,
    required this.failedAttempts,
    required this.blocked,
    required this.isLoggedIn,
    required this.blockReason,
    required this.lastFailureReason,
    required this.lastIdentifier,
    required this.lastLoginType,
    required this.lastLogoutReason,
    required this.currentSessionRevokedByName,
    required this.linkedUsers,
    this.blockedAt,
    this.lastSeenAt,
    this.lastLoginAt,
    this.lastLogoutAt,
    this.currentSessionStartedAt,
    this.currentSessionRevokedAt,
    this.currentSessionUser,
    this.matchedUserId,
    this.matchedUserName,
    this.matchedUserEmail,
    this.matchedUsername,
    this.unblockedAt,
    this.unblockedByName,
  });

  final String id;
  final String deviceId;
  final String deviceName;
  final String platform;
  final String userAgent;
  final String ipAddress;
  final int failedAttempts;
  final bool blocked;
  final bool isLoggedIn;
  final String blockReason;
  final String lastFailureReason;
  final String lastIdentifier;
  final String lastLoginType;
  final String lastLogoutReason;
  final String currentSessionRevokedByName;
  final List<ManagedDeviceUser> linkedUsers;
  final DateTime? blockedAt;
  final DateTime? lastSeenAt;
  final DateTime? lastLoginAt;
  final DateTime? lastLogoutAt;
  final DateTime? currentSessionStartedAt;
  final DateTime? currentSessionRevokedAt;
  final ManagedDeviceUser? currentSessionUser;
  final String? matchedUserId;
  final String? matchedUserName;
  final String? matchedUserEmail;
  final String? matchedUsername;
  final DateTime? unblockedAt;
  final String? unblockedByName;

  String get displayName {
    if (deviceName.trim().isNotEmpty) return deviceName.trim();
    return deviceId;
  }

  factory ManagedAuthDevice.fromJson(Map<String, dynamic> json) {
    final linkedUsersRaw = json['linkedUsers'] as List<dynamic>? ?? const [];

    return ManagedAuthDevice(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      deviceId: (json['deviceId'] ?? '').toString(),
      deviceName: (json['deviceName'] ?? '').toString(),
      platform: (json['platform'] ?? 'unknown').toString(),
      userAgent: (json['userAgent'] ?? '').toString(),
      ipAddress: (json['ipAddress'] ?? '').toString(),
      failedAttempts:
          int.tryParse(json['failedAttempts']?.toString() ?? '') ?? 0,
      blocked: json['blocked'] == true,
      isLoggedIn: json['isLoggedIn'] == true,
      blockReason: (json['blockReason'] ?? '').toString(),
      lastFailureReason: (json['lastFailureReason'] ?? '').toString(),
      lastIdentifier: (json['lastIdentifier'] ?? '').toString(),
      lastLoginType: (json['lastLoginType'] ?? '').toString(),
      lastLogoutReason: (json['lastLogoutReason'] ?? '').toString(),
      currentSessionRevokedByName: (json['currentSessionRevokedByName'] ?? '')
          .toString(),
      linkedUsers: linkedUsersRaw
          .whereType<Map>()
          .map(
            (item) =>
                ManagedDeviceUser.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      blockedAt: DateTime.tryParse(json['blockedAt']?.toString() ?? ''),
      lastSeenAt: DateTime.tryParse(json['lastSeenAt']?.toString() ?? ''),
      lastLoginAt: DateTime.tryParse(json['lastLoginAt']?.toString() ?? ''),
      lastLogoutAt: DateTime.tryParse(json['lastLogoutAt']?.toString() ?? ''),
      currentSessionStartedAt: DateTime.tryParse(
        json['currentSessionStartedAt']?.toString() ?? '',
      ),
      currentSessionRevokedAt: DateTime.tryParse(
        json['currentSessionRevokedAt']?.toString() ?? '',
      ),
      currentSessionUser: json['currentSessionUser'] is Map
          ? ManagedDeviceUser.fromJson(
              Map<String, dynamic>.from(json['currentSessionUser'] as Map),
            )
          : null,
      matchedUserId: json['matchedUserId']?.toString(),
      matchedUserName: json['matchedUserName']?.toString(),
      matchedUserEmail: json['matchedUserEmail']?.toString(),
      matchedUsername: json['matchedUsername']?.toString(),
      unblockedAt: DateTime.tryParse(json['unblockedAt']?.toString() ?? ''),
      unblockedByName: json['unblockedByName']?.toString(),
    );
  }
}
