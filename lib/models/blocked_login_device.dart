class BlockedLoginDevice {
  const BlockedLoginDevice({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.failedAttempts,
    required this.blocked,
    required this.blockReason,
    required this.lastFailureReason,
    required this.lastIdentifier,
    required this.lastLoginType,
    this.blockedAt,
    this.lastSeenAt,
    this.matchedUserId,
    this.matchedUserName,
    this.matchedUserEmail,
    this.matchedUsername,
    this.userAgent,
    this.ipAddress,
    this.unblockedAt,
    this.unblockedByName,
  });

  final String id;
  final String deviceId;
  final String deviceName;
  final String platform;
  final int failedAttempts;
  final bool blocked;
  final String blockReason;
  final String lastFailureReason;
  final String lastIdentifier;
  final String lastLoginType;
  final DateTime? blockedAt;
  final DateTime? lastSeenAt;
  final String? matchedUserId;
  final String? matchedUserName;
  final String? matchedUserEmail;
  final String? matchedUsername;
  final String? userAgent;
  final String? ipAddress;
  final DateTime? unblockedAt;
  final String? unblockedByName;

  factory BlockedLoginDevice.fromJson(Map<String, dynamic> json) {
    return BlockedLoginDevice(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      deviceId: (json['deviceId'] ?? '').toString(),
      deviceName: (json['deviceName'] ?? '').toString(),
      platform: (json['platform'] ?? 'unknown').toString(),
      failedAttempts:
          int.tryParse(json['failedAttempts']?.toString() ?? '') ?? 0,
      blocked: json['blocked'] == true,
      blockReason: (json['blockReason'] ?? '').toString(),
      lastFailureReason: (json['lastFailureReason'] ?? '').toString(),
      lastIdentifier: (json['lastIdentifier'] ?? '').toString(),
      lastLoginType: (json['lastLoginType'] ?? '').toString(),
      blockedAt: DateTime.tryParse(json['blockedAt']?.toString() ?? ''),
      lastSeenAt: DateTime.tryParse(json['lastSeenAt']?.toString() ?? ''),
      matchedUserId: json['matchedUserId']?.toString(),
      matchedUserName: json['matchedUserName']?.toString(),
      matchedUserEmail: json['matchedUserEmail']?.toString(),
      matchedUsername: json['matchedUsername']?.toString(),
      userAgent: json['userAgent']?.toString(),
      ipAddress: json['ipAddress']?.toString(),
      unblockedAt: DateTime.tryParse(json['unblockedAt']?.toString() ?? ''),
      unblockedByName: json['unblockedByName']?.toString(),
    );
  }
}
