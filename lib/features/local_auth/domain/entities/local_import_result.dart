class LocalImportResult {
  const LocalImportResult({
    required this.importedRats,
    required this.ignoredDuplicates,
    required this.skippedConflicts,
    required this.overwrittenConflicts,
    required this.importedAssinaturas,
  });

  final int importedRats;
  final int ignoredDuplicates;
  final int skippedConflicts;
  final int overwrittenConflicts;
  final int importedAssinaturas;
}
