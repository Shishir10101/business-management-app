/// Sync domain entities. Pure Dart, no Flutter or serialization concerns.
library;

/// One queued local write waiting to reach the server.
///
/// [payload] is the client-side JSON body sent with a create/update push.
/// [baseUpdatedAt] is the record's `updatedAt` as last seen by this client;
/// the server uses it to detect that its own copy moved on (a conflict).
class QueuedOperation {
  final String operationId;
  final String entityType;
  final String operation; // create | update | delete
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime? baseUpdatedAt;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;

  const QueuedOperation({
    required this.operationId,
    required this.entityType,
    required this.operation,
    required this.entityId,
    this.payload = const {},
    this.baseUpdatedAt,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  QueuedOperation copyWith({int? attempts, String? lastError}) =>
      QueuedOperation(
        operationId: operationId,
        entityType: entityType,
        operation: operation,
        entityId: entityId,
        payload: payload,
        baseUpdatedAt: baseUpdatedAt,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
      );

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'entityType': entityType,
        'operation': operation,
        'entityId': entityId,
        'payload': payload,
        if (baseUpdatedAt != null)
          'baseUpdatedAt': baseUpdatedAt!.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        if (lastError != null) 'lastError': lastError,
      };

  static QueuedOperation fromJson(Map<String, dynamic> json) => QueuedOperation(
        operationId: json['operationId'] as String,
        entityType: json['entityType'] as String? ?? '',
        operation: json['operation'] as String? ?? 'update',
        entityId: (json['entityId'] ?? '').toString(),
        payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
        baseUpdatedAt: DateTime.tryParse(
          json['baseUpdatedAt'] as String? ?? '',
        ),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        lastError: json['lastError'] as String?,
      );
}

/// Handle returned when a write is enqueued locally.
class SyncOperationHandle {
  final String operationId;
  final String entityType;
  final String entityId;
  final String operation;

  const SyncOperationHandle({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.operation,
  });
}

/// A push the server refused because its copy is newer than the client's
/// [baseUpdatedAt]. The server version is surfaced, never overwritten.
class SyncConflict {
  final String entityType;
  final String entityId;
  final String operation;
  final Map<String, dynamic>? serverVersion;
  final DateTime? serverChangedAt;
  final String? message;

  const SyncConflict({
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.serverVersion,
    this.serverChangedAt,
    this.message,
  });

  Map<String, dynamic> toJson() => {
        'entityType': entityType,
        'entityId': entityId,
        'operation': operation,
        if (serverVersion != null) 'serverVersion': serverVersion,
        if (serverChangedAt != null)
          'serverChangedAt': serverChangedAt!.toIso8601String(),
        if (message != null) 'message': message,
      };

  static SyncConflict fromJson(Map<String, dynamic> json) => SyncConflict(
        entityType: json['entityType'] as String? ?? '',
        entityId: (json['entityId'] ?? '').toString(),
        operation: json['operation'] as String? ?? '',
        serverVersion: json['serverVersion'] as Map<String, dynamic>?,
        serverChangedAt: DateTime.tryParse(
          json['serverChangedAt'] as String? ?? '',
        ),
        message: json['message'] as String?,
      );
}

/// A queued operation the server rejected outright (validation, etc.).
class SyncRejection {
  final String operationId;
  final String entityType;
  final String entityId;
  final String? error;

  const SyncRejection({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    this.error,
  });
}

/// What one full sync cycle (push then pull) accomplished.
class SyncOutcome {
  final int pushed;
  final int pulled;
  final int conflicts;
  final int rejected;
  final List<SyncConflict> conflictDetails;
  final List<SyncRejection> rejections;
  final DateTime serverTime;
  final int pendingCount;

  const SyncOutcome({
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = 0,
    this.rejected = 0,
    this.conflictDetails = const [],
    this.rejections = const [],
    required this.serverTime,
    this.pendingCount = 0,
  });
}

/// Server snapshot from GET /sync/status.
class SyncServerStatus {
  final DateTime serverTime;
  final int storedOperations;
  final int pendingConflicts;

  const SyncServerStatus({
    required this.serverTime,
    this.storedOperations = 0,
    this.pendingConflicts = 0,
  });
}
