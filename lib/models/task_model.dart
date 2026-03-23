class TaskAttachment {
  final String filename;
  final String path;
  final String fileType;
  final String attachmentType;
  final String? uploadedByName;
  final DateTime? uploadedAt;

  TaskAttachment({
    required this.filename,
    required this.path,
    required this.fileType,
    required this.attachmentType,
    this.uploadedByName,
    this.uploadedAt,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      filename: json['filename']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
      attachmentType: json['attachmentType']?.toString() ?? 'file',
      uploadedByName: json['uploadedByName']?.toString(),
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
          : null,
    );
  }
}

class TaskMessageAttachment {
  final String filename;
  final String path;
  final String fileType;

  TaskMessageAttachment({
    required this.filename,
    required this.path,
    required this.fileType,
  });

  factory TaskMessageAttachment.fromJson(Map<String, dynamic> json) {
    return TaskMessageAttachment(
      filename: json['filename']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
    );
  }
}

class TaskParticipant {
  final String userId;
  final String name;
  final DateTime? addedAt;
  final String? addedByName;

  TaskParticipant({
    required this.userId,
    required this.name,
    this.addedAt,
    this.addedByName,
  });

  factory TaskParticipant.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String userId;
    if (user is Map) {
      userId = user['_id']?.toString() ?? user[r'$oid']?.toString() ?? '';
    } else {
      userId = user?.toString() ?? '';
    }
    return TaskParticipant(
      userId: userId,
      name: json['name']?.toString() ?? '',
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'].toString())
          : null,
      addedByName: json['addedByName']?.toString(),
    );
  }
}

class TaskMessage {
  final String messageType;
  final String? text;
  final String? senderId;
  final String? senderName;
  final DateTime? createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final TaskMessageAttachment? attachment;

  TaskMessage({
    required this.messageType,
    this.text,
    this.senderId,
    this.senderName,
    this.createdAt,
    this.deliveredAt,
    this.readAt,
    this.attachment,
  });

  factory TaskMessage.fromJson(Map<String, dynamic> json) {
    String? senderId;
    final sender = json['sender'];
    if (sender is Map) {
      senderId = sender['_id']?.toString() ?? sender[r'$oid']?.toString();
    } else {
      senderId = sender?.toString();
    }
    return TaskMessage(
      messageType: json['messageType']?.toString() ?? 'text',
      text: json['text']?.toString(),
      senderId: senderId,
      senderName: json['senderName']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'].toString())
          : null,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      attachment: json['attachment'] is Map<String, dynamic>
          ? TaskMessageAttachment.fromJson(
              Map<String, dynamic>.from(json['attachment']),
            )
          : null,
    );
  }
}

class TaskReport {
  final String pdfPath;
  final String summary;
  final String? completedByName;
  final String? completedNotes;
  final DateTime? generatedAt;

  TaskReport({
    required this.pdfPath,
    required this.summary,
    this.completedByName,
    this.completedNotes,
    this.generatedAt,
  });

  factory TaskReport.fromJson(Map<String, dynamic> json) {
    return TaskReport(
      pdfPath: json['pdfPath']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      completedByName: json['completedByName']?.toString(),
      completedNotes: json['completedNotes']?.toString(),
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString())
          : null,
    );
  }
}

class TaskOverduePenalty {
  final bool enabled;
  final double amount;
  final String currency;
  final String status;
  final DateTime? configuredAt;
  final DateTime? appliedAt;
  final String? appliedByName;
  final String voucherNumber;
  final String voucherPath;
  final String notes;

  const TaskOverduePenalty({
    required this.enabled,
    required this.amount,
    required this.currency,
    required this.status,
    this.configuredAt,
    this.appliedAt,
    this.appliedByName,
    this.voucherNumber = '',
    this.voucherPath = '',
    this.notes = '',
  });

  bool get isConfigured => status == 'configured' && enabled && amount > 0;
  bool get isApplied => status == 'applied';

  factory TaskOverduePenalty.fromJson(Map<String, dynamic> json) {
    return TaskOverduePenalty(
      enabled: json['enabled'] == true,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      currency: json['currency']?.toString() ?? 'SAR',
      status: json['status']?.toString() ?? 'none',
      configuredAt: json['configuredAt'] != null
          ? DateTime.tryParse(json['configuredAt'].toString())
          : null,
      appliedAt: json['appliedAt'] != null
          ? DateTime.tryParse(json['appliedAt'].toString())
          : null,
      appliedByName: json['appliedByName']?.toString(),
      voucherNumber: json['voucherNumber']?.toString() ?? '',
      voucherPath: json['voucherPath']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class TaskExtensionRequest {
  final String status;
  final String? requestedByName;
  final DateTime? requestedAt;
  final int requestedSeconds;
  final String requestedReason;
  final String? decidedByName;
  final DateTime? decidedAt;
  final String decisionReason;

  const TaskExtensionRequest({
    required this.status,
    this.requestedByName,
    this.requestedAt,
    this.requestedSeconds = 0,
    this.requestedReason = '',
    this.decidedByName,
    this.decidedAt,
    this.decisionReason = '',
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get hasRequest => status != 'none';

  factory TaskExtensionRequest.fromJson(Map<String, dynamic> json) {
    return TaskExtensionRequest(
      status: json['status']?.toString() ?? 'none',
      requestedByName: json['requestedByName']?.toString(),
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : null,
      requestedSeconds:
          int.tryParse(json['requestedSeconds']?.toString() ?? '0') ?? 0,
      requestedReason: json['requestedReason']?.toString() ?? '',
      decidedByName: json['decidedByName']?.toString(),
      decidedAt: json['decidedAt'] != null
          ? DateTime.tryParse(json['decidedAt'].toString())
          : null,
      decisionReason: json['decisionReason']?.toString() ?? '',
    );
  }
}

class TaskTargetLocation {
  final String? address;
  final double? latitude;
  final double? longitude;

  TaskTargetLocation({this.address, this.latitude, this.longitude});

  factory TaskTargetLocation.fromJson(Map<String, dynamic> json) {
    return TaskTargetLocation(
      address: json['address']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    final parsed = double.tryParse(value.toString());
    return parsed;
  }
}

class TaskTrackingPoint {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final DateTime? timestamp;
  final String? userName;

  TaskTrackingPoint({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.timestamp,
    this.userName,
  });

  factory TaskTrackingPoint.fromJson(Map<String, dynamic> json) {
    return TaskTrackingPoint(
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0,
      accuracy: json['accuracy'] != null
          ? double.tryParse(json['accuracy'].toString())
          : null,
      speed: json['speed'] != null
          ? double.tryParse(json['speed'].toString())
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      userName: json['userName']?.toString(),
    );
  }
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String department;
  final String status;
  final String taskCode;
  final String assignedTo;
  final String assignedToName;
  final String createdBy;
  final String createdByName;
  final int countdownDurationSeconds;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final String? statusBeforeOverdue;
  final DateTime? overdueNotifiedAt;
  final TaskTargetLocation? location;
  final TaskReport? report;
  final TaskOverduePenalty? overduePenalty;
  final TaskExtensionRequest? extensionRequest;
  final List<TaskAttachment> attachments;
  final List<TaskMessage> messages;
  final List<TaskParticipant> participants;
  final bool trackingConsent;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.department,
    required this.status,
    required this.taskCode,
    required this.assignedTo,
    required this.assignedToName,
    required this.createdBy,
    required this.createdByName,
    this.countdownDurationSeconds = 0,
    this.assignedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.dueDate,
    this.statusBeforeOverdue,
    this.overdueNotifiedAt,
    this.location,
    this.report,
    this.overduePenalty,
    this.extensionRequest,
    this.attachments = const [],
    this.messages = const [],
    this.participants = const [],
    this.trackingConsent = false,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      taskCode: json['taskCode']?.toString() ?? '',
      assignedTo: json['assignedTo']?.toString() ?? '',
      assignedToName: json['assignedToName']?.toString() ?? '',
      createdBy: json['createdBy']?.toString() ?? '',
      createdByName: json['createdByName']?.toString() ?? '',
      countdownDurationSeconds:
          int.tryParse(json['countdownDurationSeconds']?.toString() ?? '0') ??
          0,
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'].toString())
          : null,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'].toString())
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())
          : null,
      statusBeforeOverdue: json['statusBeforeOverdue']?.toString(),
      overdueNotifiedAt: json['overdueNotifiedAt'] != null
          ? DateTime.tryParse(json['overdueNotifiedAt'].toString())
          : null,
      location: json['location'] is Map<String, dynamic>
          ? TaskTargetLocation.fromJson(
              Map<String, dynamic>.from(json['location']),
            )
          : null,
      report: json['report'] is Map<String, dynamic>
          ? TaskReport.fromJson(Map<String, dynamic>.from(json['report']))
          : null,
      overduePenalty: json['overduePenalty'] is Map<String, dynamic>
          ? TaskOverduePenalty.fromJson(
              Map<String, dynamic>.from(json['overduePenalty']),
            )
          : null,
      extensionRequest: json['extensionRequest'] is Map<String, dynamic>
          ? TaskExtensionRequest.fromJson(
              Map<String, dynamic>.from(json['extensionRequest']),
            )
          : null,
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TaskAttachment.fromJson)
          .toList(),
      messages: (json['messages'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TaskMessage.fromJson)
          .toList(),
      participants: (json['participants'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TaskParticipant.fromJson)
          .toList(),
      trackingConsent: json['trackingConsent'] == true,
    );
  }

  bool get isDone => status == 'completed' || status == 'approved';

  bool get hasDeadline => dueDate != null;

  bool get isDeadlineExpired {
    if (dueDate == null || isDone) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  Duration? get deadlineRemaining =>
      dueDate == null ? null : dueDate!.difference(DateTime.now());

  List<String> get workerNames {
    final values = <String>[];
    if (assignedToName.trim().isNotEmpty) {
      values.add(assignedToName.trim());
    }
    for (final participant in participants) {
      final name = participant.name.trim();
      if (name.isNotEmpty && !values.contains(name)) {
        values.add(name);
      }
    }
    return values;
  }
}
