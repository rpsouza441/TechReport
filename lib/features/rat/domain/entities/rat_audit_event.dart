enum RatAuditEventType { created, updated, trashed, restored }

class RatAuditFieldDiff {
  const RatAuditFieldDiff({
    required this.field,
    required this.label,
    required this.beforeValue,
    required this.afterValue,
  });

  final String field;
  final String label;
  final String? beforeValue;
  final String? afterValue;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RatAuditFieldDiff &&
            other.field == field &&
            other.label == label &&
            other.beforeValue == beforeValue &&
            other.afterValue == afterValue;
  }

  @override
  int get hashCode => Object.hash(field, label, beforeValue, afterValue);
}

class RatAuditEvent {
  RatAuditEvent({
    required this.id,
    required this.ratId,
    required this.type,
    required this.actorUserId,
    required this.actorName,
    required this.editedAt,
    required Iterable<RatAuditFieldDiff> diffs,
  }) : diffs = List<RatAuditFieldDiff>.unmodifiable(diffs);

  final String id;
  final String ratId;
  final RatAuditEventType type;
  final String actorUserId;
  final String actorName;
  final DateTime editedAt;
  final List<RatAuditFieldDiff> diffs;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RatAuditEvent &&
            other.id == id &&
            other.ratId == ratId &&
            other.type == type &&
            other.actorUserId == actorUserId &&
            other.actorName == actorName &&
            other.editedAt == editedAt &&
            _listEquals(other.diffs, diffs);
  }

  @override
  int get hashCode => Object.hash(
    id,
    ratId,
    type,
    actorUserId,
    actorName,
    editedAt,
    Object.hashAll(diffs),
  );
}

class RatAuditCursor {
  const RatAuditCursor({required this.editedAt, required this.id});

  final DateTime editedAt;
  final String id;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RatAuditCursor && other.editedAt == editedAt && other.id == id;
  }

  @override
  int get hashCode => Object.hash(editedAt, id);
}

class RatAuditPage {
  RatAuditPage({
    required Iterable<RatAuditEvent> events,
    required this.nextCursor,
  }) : events = List<RatAuditEvent>.unmodifiable(events);

  final List<RatAuditEvent> events;
  final RatAuditCursor? nextCursor;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RatAuditPage &&
            _listEquals(other.events, events) &&
            other.nextCursor == nextCursor;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(events), nextCursor);
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
