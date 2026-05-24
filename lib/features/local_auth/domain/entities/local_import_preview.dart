class LocalImportPreview {
  const LocalImportPreview({
    required this.schema,
    required this.exportedAt,
    required this.totalRats,
    required this.totalAssinaturas,
    required this.newRats,
    required this.duplicateRats,
    required this.conflictingRats,
    required this.invalidItems,
  });

  final String schema;
  final DateTime? exportedAt;
  final int totalRats;
  final int totalAssinaturas;
  final int newRats;
  final int duplicateRats;
  final int conflictingRats;
  final int invalidItems;

  bool get canApply => invalidItems == 0;

  bool get hasConflicts => conflictingRats > 0;
}
