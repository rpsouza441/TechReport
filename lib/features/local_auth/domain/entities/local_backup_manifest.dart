class LocalBackupManifest {
  const LocalBackupManifest({
    required this.schema,
    required this.createdAt,
    required this.appVersion,
    required this.databaseSchemaVersion,
    required this.counts,
    required this.checksums,
  });

  final String schema;
  final DateTime createdAt;
  final String appVersion;
  final int databaseSchemaVersion;
  final Counts counts;
  final Map<String, String> checksums;

  factory LocalBackupManifest.fromJson(Map<String, dynamic> json) {
    return LocalBackupManifest(
      schema: json['schema'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      appVersion: json['appVersion'] as String,
      databaseSchemaVersion: json['databaseSchemaVersion'] as int,
      counts: Counts.fromJson(json['counts'] as Map<String, dynamic>),
      checksums: (json['checksums'] as Map<String, dynamic>)
          .cast<String, String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schema': schema,
      'createdAt': createdAt.toIso8601String(),
      'appVersion': appVersion,
      'databaseSchemaVersion': databaseSchemaVersion,
      'counts': counts.toJson(),
      'checksums': checksums,
    };
  }
}

class Counts {
  const Counts({
    required this.rats,
    required this.assinaturas,
    this.ratsActive,
    this.ratsTrash,
  });

  final int rats;
  final int assinaturas;
  final int? ratsActive;
  final int? ratsTrash;

  factory Counts.fromJson(Map<String, dynamic> json) {
    final rats = json['rats'];
    final assinaturas = json['assinaturas'];
    final ratsActive = json['ratsActive'];
    final ratsTrash = json['ratsTrash'];
    if (rats is! int || rats < 0 || assinaturas is! int || assinaturas < 0) {
      throw const FormatException('Contagens de backup invalidas.');
    }
    final hasAnySplit = ratsActive != null || ratsTrash != null;
    if (hasAnySplit &&
        (ratsActive is! int ||
            ratsActive < 0 ||
            ratsTrash is! int ||
            ratsTrash < 0 ||
            ratsActive + ratsTrash != rats)) {
      throw const FormatException('Contagens ativa/lixeira inconsistentes.');
    }
    return Counts(
      rats: rats,
      assinaturas: assinaturas,
      ratsActive: ratsActive as int?,
      ratsTrash: ratsTrash as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rats': rats,
      'assinaturas': assinaturas,
      if (ratsActive != null) 'ratsActive': ratsActive,
      if (ratsTrash != null) 'ratsTrash': ratsTrash,
    };
  }
}
