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
  const Counts({required this.rats, required this.assinaturas});

  final int rats;
  final int assinaturas;

  factory Counts.fromJson(Map<String, dynamic> json) {
    return Counts(
      rats: json['rats'] as int,
      assinaturas: json['assinaturas'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'rats': rats, 'assinaturas': assinaturas};
  }
}
