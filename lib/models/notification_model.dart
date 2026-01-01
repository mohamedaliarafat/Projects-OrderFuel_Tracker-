class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final List<NotificationRecipient> recipients;
  final String? createdById;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime expiresAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.recipients,
    this.createdById,
    this.createdByName,
    required this.createdAt,
    required this.expiresAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      recipients: (json['recipients'] as List<dynamic>)
          .map((e) => NotificationRecipient.fromJson(e))
          .toList(),
      createdById: json['createdBy'] is String
          ? json['createdBy']
          : json['createdBy']?['_id'],
      createdByName: json['createdBy'] is Map
          ? json['createdBy']['name']
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }

  // دالة لإنشاء نسخة جديدة مع قراءة محدثة
  NotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    List<NotificationRecipient>? recipients,
    String? createdById,
    String? createdByName,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      recipients: recipients ?? this.recipients,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // دالة لتحديث حالة القراءة لمستلم معين
  NotificationModel markAsReadForUser(String userId) {
    final updatedRecipients = recipients.map((recipient) {
      if (recipient.userId == userId && !recipient.read) {
        return NotificationRecipient(
          userId: recipient.userId,
          read: true,
          readAt: DateTime.now(),
        );
      }
      return recipient;
    }).toList();

    return copyWith(recipients: updatedRecipients);
  }

  // دالة للتحقق مما إذا كان المستخدم قد قرأ الإشعار
  bool isReadByUser(String userId) {
    final recipient = recipients.firstWhere(
      (r) => r.userId == userId,
      orElse: () => NotificationRecipient(userId: '', read: true),
    );
    return recipient.read;
  }

  // دالة للحصول على المستلم الخاص بالمستخدم الحالي
  NotificationRecipient? getRecipientForUser(String userId) {
    try {
      return recipients.firstWhere((r) => r.userId == userId);
    } catch (e) {
      return null;
    }
  }
}

class NotificationRecipient {
  final String userId;
  final bool read;
  final DateTime? readAt;

  NotificationRecipient({
    required this.userId,
    required this.read,
    this.readAt,
  });

  factory NotificationRecipient.fromJson(Map<String, dynamic> json) {
    return NotificationRecipient(
      userId: json['user'] is String ? json['user'] : json['user']?['_id'],
      read: json['read'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }
}
