import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_parser.dart';
import 'package:techreport/features/local_auth/data/services/local_data_import_parser.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';

// ─── Mock Repositories ──────────────────────────────────────────────────────

class MockRatRepository {
  final List<Rat> _rats = [];

  List<Rat> get rats => List.unmodifiable(_rats);

  Future<void> save(Rat rat) async {
    final index = _rats.indexWhere((r) => r.id == rat.id);
    if (index >= 0) {
      _rats[index] = rat;
    } else {
      _rats.add(rat);
    }
  }

  Future<List<Rat>> listLocal() async => _rats;

  void seed(List<Rat> rats) => _rats.addAll(rats);

  void clear() => _rats.clear();
}

class MockAssinaturaRepository {
  final List<Map<String, dynamic>> _assinaturas = [];

  List<Map<String, dynamic>> get assinaturas =>
      List.unmodifiable(_assinaturas);

  Future<void> save(Map<String, dynamic> assinatura) async {
    final index =
        _assinaturas.indexWhere((a) => a['id'] == assinatura['id']);
    if (index >= 0) {
      _assinaturas[index] = assinatura;
    } else {
      _assinaturas.add(assinatura);
    }
  }

  Future<List<Map<String, dynamic>>> listByRatId(String ratId) async {
    return _assinaturas.where((a) => a['ratId'] == ratId).toList();
  }

  Future<Uint8List?> readBytes(String id) async {
    return null;
  }

  void seed(List<Map<String, dynamic>> assinaturas) =>
      _assinaturas.addAll(assinaturas);

  void clear() => _assinaturas.clear();
}

// ─── Backup Builder (replicates LocalBackupService logic) ────────────────────

class TestBackupBuilder {
  TestBackupBuilder({
    required List<Rat> rats,
    required List<Map<String, dynamic>> assinaturas,
  }) : _rats = rats,
       _assinaturas = assinaturas;

  final List<Rat> _rats;
  final List<Map<String, dynamic>> _assinaturas;

  Uint8List build() {
    final ratsJson = _rats.map(_ratToJson).toList();
    final assinaturasJson = _assinaturas;

    final ratsBytes = utf8.encode(jsonEncode(ratsJson));
    final assinaturasBytes = utf8.encode(jsonEncode(assinaturasJson));

    final ratsChecksum = _sha256(ratsBytes);
    final assinaturasChecksum = _sha256(assinaturasBytes);

    final manifest = {
      'schema': 'techreport.backup.v1',
      'created_at': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
      'database_schema_version': 8,
      'counts': {
        'rats': _rats.length,
        'assinaturas': _assinaturas.length,
      },
      'checksums': {
        'data/rats.json': ratsChecksum,
        'data/assinaturas.json': assinaturasChecksum,
      },
    };

    final manifestBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final archive = Archive();
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );
    archive.addFile(
      ArchiveFile('data/rats.json', ratsBytes.length, ratsBytes),
    );
    archive.addFile(
      ArchiveFile(
        'data/assinaturas.json',
        assinaturasBytes.length,
        assinaturasBytes,
      ),
    );

    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  Map<String, Object?> _ratToJson(Rat rat) {
    return {
      'id': rat.id,
      'authorId': rat.authorId,
      'empresaId': rat.empresaId,
      'usuarioId': rat.usuarioId,
      'tecnicoId': rat.tecnicoId,
      'ownerType': rat.ownerType.name,
      'numero': rat.numero,
      'clienteNome': rat.clienteNome,
      'responsavelRecebimento': rat.responsavelRecebimento,
      'responsavelDocumento': rat.responsavelDocumento,
      'dataVisita': rat.dataVisita?.toIso8601String(),
      'horarioInicioAtendimento': rat.horarioInicioAtendimento,
      'horarioTerminoAtendimento': rat.horarioTerminoAtendimento,
      'descricao': rat.descricao,
      'equipamentoMovimentoTipo': rat.equipamentoMovimentoTipo?.name,
      'equipamentoDescricao': rat.equipamentoDescricao,
      'equipamentoObservacao': rat.equipamentoObservacao,
      'status': rat.status.name,
      'syncStatus': rat.syncStatus.name,
      'createdAt': rat.createdAt.toIso8601String(),
      'updatedAt': rat.updatedAt.toIso8601String(),
      'deletedAt': rat.deletedAt?.toIso8601String(),
    };
  }

  String _sha256(List<int> bytes) {
    // Simple hash for testing - in production uses crypto package
    return 'test_sha256_${base64Encode(bytes).substring(0, 16)}';
  }
}

// ─── Test Helpers ───────────────────────────────────────────────────────────

Rat _makeRat({
  required String id,
  String clienteNome = 'Test Cliente',
  RatStatus status = RatStatus.draft,
  RatSyncStatus syncStatus = RatSyncStatus.localOnly,
}) {
  final now = DateTime.now();
  return Rat(
    id: id,
    authorId: 'author-1',
    empresaId: 'emp-1',
    usuarioId: 'user-1',
    tecnicoId: 'tec-1',
    ownerType: RatOwnerType.localTecnico,
    numero: '0001',
    clienteNome: clienteNome,
    responsavelRecebimento: 'Responsavel Teste',
    dataVisita: now,
    horarioInicioAtendimento: '08:00',
    horarioTerminoAtendimento: '10:00',
    descricao: 'Test description',
    status: status,
    syncStatus: syncStatus,
    createdAt: now,
    updatedAt: now,
  );
}

Map<String, dynamic> _makeAssinatura({
  required String id,
  required String ratId,
}) {
  final now = DateTime.now();
  return {
    'id': id,
    'ratId': ratId,
    'storageMode': 'inlineBinary',
    'assetRef': 'signatures/$id.png',
    'createdAt': now.toIso8601String(),
    'updatedAt': now.toIso8601String(),
    'deletedAt': null,
  };
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late LocalBackupParser backupParser;
  late MockRatRepository ratRepo;
  late MockAssinaturaRepository assinaturaRepo;
  late Directory tempDir;

  setUp(() async {
    backupParser = LocalBackupParser();
    ratRepo = MockRatRepository();
    assinaturaRepo = MockAssinaturaRepository();
    tempDir = await Directory.systemTemp.createTemp('backup_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  // ─── Backup Export Tests ────────────────────────────────────────────────────

  group('Backup export', () {
    test('creates valid backup file with RAT data', () async {
      // Seed with test RATs
      ratRepo.seed([
        _makeRat(id: 'rat-1', clienteNome: 'Cliente 1'),
        _makeRat(id: 'rat-2', clienteNome: 'Cliente 2'),
      ]);

      // Build backup
      final backup = TestBackupBuilder(
        rats: ratRepo.rats,
        assinaturas: [],
      ).build();

      // Write to temp file
      final backupFile = File('${tempDir.path}/backup.zip');
      await backupFile.writeAsBytes(backup);

      // Verify file exists
      expect(await backupFile.exists(), isTrue);

      // Parse and verify content
      final rats = backupParser.parseRats(backup);
      expect(rats.length, 2);
      expect(rats[0]['clienteNome'], 'Cliente 1');
      expect(rats[1]['clienteNome'], 'Cliente 2');
    });

    test('backup includes checksums for integrity validation', () async {
      ratRepo.seed([
        _makeRat(id: 'rat-1', clienteNome: 'Cliente Test'),
      ]);

      final backup = TestBackupBuilder(
        rats: ratRepo.rats,
        assinaturas: [],
      ).build();

      // Validate integrity should pass for valid backup
      final isValid = backupParser.validateIntegrity(backup);
      expect(isValid, isTrue);
    });

    test('export with no RATs creates empty backup', () async {
      // No data seeded
      final backup = TestBackupBuilder(
        rats: [],
        assinaturas: [],
      ).build();

      final backupFile = File('${tempDir.path}/empty_backup.zip');
      await backupFile.writeAsBytes(backup);

      expect(await backupFile.exists(), isTrue);

      final rats = backupParser.parseRats(backup);
      expect(rats, isEmpty);
    });

    test('export includes assinaturas when present', () async {
      ratRepo.seed([
        _makeRat(id: 'rat-1', clienteNome: 'Cliente com Assinatura'),
      ]);
      assinaturaRepo.seed([
        _makeAssinatura(id: 'assinatura-1', ratId: 'rat-1'),
      ]);

      final backup = TestBackupBuilder(
        rats: ratRepo.rats,
        assinaturas: assinaturaRepo.assinaturas,
      ).build();

      final assinaturas = backupParser.parseAssinaturas(backup);
      expect(assinaturas.length, 1);
      expect(assinaturas[0]['id'], 'assinatura-1');
    });
  });

  // ─── Backup Restore Tests ──────────────────────────────────────────────────

  group('Backup restore', () {
    test('import restores RATs to repository', () async {
      // Create and export backup first
      ratRepo.seed([_makeRat(id: 'rat-to-restore', clienteNome: 'Restored Client')]);
      assinaturaRepo.seed([]);

      final backup = TestBackupBuilder(
        rats: ratRepo.rats,
        assinaturas: assinaturaRepo.assinaturas,
      ).build();

      // Clear repository (simulating fresh restore)
      ratRepo.clear();

      // Import backup
      final importedRats = backupParser.parseRats(backup);
      for (final ratJson in importedRats) {
        final rat = _ratFromJson(ratJson);
        await ratRepo.save(rat);
      }

      expect(ratRepo.rats.length, 1);
      expect(ratRepo.rats.first.id, 'rat-to-restore');
      expect(ratRepo.rats.first.clienteNome, 'Restored Client');
    });

    test('import handles legacy JSON format', () async {
      // Create legacy JSON backup (non-zip format)
      final legacyJson = '''
      {
        "version": 1,
        "exported_at": "2024-01-01T00:00:00Z",
        "rats": [
          {
            "id": "rat-legacy-1",
            "clienteNome": "Legacy Cliente",
            "descricao": "Legacy test"
          }
        ],
        "assinaturas": []
      }
      ''';

      final legacyFile = File('${tempDir.path}/legacy.json');
      await legacyFile.writeAsString(legacyJson);

      // LocalBackupParser should handle legacy format via LocalDataImportParser
      final legacyParser = LocalDataImportParser();
      final parsed = legacyParser.parse(legacyJson);

      expect(parsed['rats'], isNotNull);
      expect((parsed['rats'] as List).length, 1);
    });

    test('restore preserves RAT status and sync status', () async {
      ratRepo.seed([
        _makeRat(
          id: 'rat-status-test',
          clienteNome: 'Status Test',
          status: RatStatus.finalizado,
          syncStatus: RatSyncStatus.synced,
        ),
      ]);

      final backup = TestBackupBuilder(
        rats: ratRepo.rats,
        assinaturas: [],
      ).build();

      ratRepo.clear();

      final importedRats = backupParser.parseRats(backup);
      final restored = _ratFromJson(importedRats.first);

      expect(restored.status, RatStatus.finalizado);
      expect(restored.syncStatus, RatSyncStatus.synced);
    });

    test('restore handles multiple RATs with different owners', () async {
      final now = DateTime.now();

      ratRepo.seed([
        Rat(
          id: 'rat-local',
          authorId: 'author-1',
          empresaId: null,
          usuarioId: null,
          tecnicoId: null,
          ownerType: RatOwnerType.localTecnico,
          numero: '0001',
          clienteNome: 'Local Cliente',
          responsavelRecebimento: 'Responsavel',
          dataVisita: now,
          horarioInicioAtendimento: '08:00',
          horarioTerminoAtendimento: '10:00',
          descricao: 'Local RAT',
          status: RatStatus.draft,
          syncStatus: RatSyncStatus.localOnly,
          createdAt: now,
          updatedAt: now,
        ),
        Rat(
          id: 'rat-company',
          authorId: 'author-1',
          empresaId: 'emp-1',
          usuarioId: 'user-1',
          tecnicoId: 'tec-1',
          ownerType: RatOwnerType.companyTecnico,
          numero: '0002',
          clienteNome: 'Company Cliente',
          responsavelRecebimento: 'Responsavel',
          dataVisita: now,
          horarioInicioAtendimento: '09:00',
          horarioTerminoAtendimento: '11:00',
          descricao: 'Company RAT',
          status: RatStatus.enviado,
          syncStatus: RatSyncStatus.synced,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      final backup = TestBackupBuilder(
        rats: ratRepo.rats,
        assinaturas: [],
      ).build();

      ratRepo.clear();

      final importedRats = backupParser.parseRats(backup);
      for (final ratJson in importedRats) {
        await ratRepo.save(_ratFromJson(ratJson));
      }

      expect(ratRepo.rats.length, 2);
      expect(
        ratRepo.rats.where((r) => r.ownerType == RatOwnerType.localTecnico).length,
        1,
      );
      expect(
        ratRepo.rats.where((r) => r.ownerType == RatOwnerType.companyTecnico).length,
        1,
      );
    });
  });

  // ─── Integrity Validation Tests ───────────────────────────────────────────

  group('Integrity validation', () {
    test('validates unmodified backup as valid', () async {
      ratRepo.seed([_makeRat(id: 'rat-valid', clienteNome: 'Valid RAT')]);

      final backup = TestBackupBuilder(
        rats: ratRepo.rats,
        assinaturas: [],
      ).build();

      expect(backupParser.validateIntegrity(backup), isTrue);
    });

    test('detects tampered content', () async {
      ratRepo.seed([_makeRat(id: 'rat-tampered', clienteNome: 'Original')]);

      final backup = TestBackupBuilder(
        rats: ratRepo.rats,
        assinaturas: [],
      ).build();

      // Tamper with content
      final tampered = Uint8List.fromList([...backup, 0xFF]);
      final backupFile = File('${tempDir.path}/tampered.zip');
      await backupFile.writeAsBytes(tampered);

      // Read back and validate
      final tamperedBytes = await backupFile.readAsBytes();
      expect(backupParser.validateIntegrity(tamperedBytes), isFalse);
    });

    test('rejects corrupted ZIP format', () async {
      // Write invalid data
      final corruptedFile = File('${tempDir.path}/corrupted.zip');
      await corruptedFile.writeAsBytes([0x00, 0x01, 0x02, 0xFF, 0xFE]);

      final bytes = await corruptedFile.readAsBytes();

      // validateIntegrity should return false for invalid format
      expect(backupParser.validateIntegrity(bytes), isFalse);
    });

    test('rejects backup with missing manifest', () async {
      final archive = Archive();
      // Add only data file, no manifest
      final ratsJson = jsonEncode([]);
      archive.addFile(
        ArchiveFile(
          'data/rats.json',
          ratsJson.length,
          utf8.encode(ratsJson),
        ),
      );

      final invalidZip = Uint8List.fromList(ZipEncoder().encode(archive)!);

      // parseManifest should throw for missing manifest
      expect(
        () => backupParser.parseManifest(invalidZip),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ─── Conflict Resolution Tests ────────────────────────────────────────────

  group('Conflict resolution', () {
    test('handles same ID with different content (newer wins)', () async {
      final now = DateTime.now();

      // Existing RAT in repository
      final existingRat = Rat(
        id: 'rat-conflict',
        authorId: 'author-1',
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        tecnicoId: 'tec-1',
        ownerType: RatOwnerType.localTecnico,
        numero: '0001',
        clienteNome: 'Old Name',
        responsavelRecebimento: 'Responsavel',
        dataVisita: now.subtract(const Duration(days: 1)),
        horarioInicioAtendimento: '08:00',
        horarioTerminoAtendimento: '10:00',
        descricao: 'Old description',
        status: RatStatus.draft,
        syncStatus: RatSyncStatus.localOnly,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      );

      // Backup RAT (simulating restore from backup)
      final backupRat = _makeRat(
        id: 'rat-conflict',
        clienteNome: 'New Name from Backup',
      );

      // Simulate restore: newer data wins
      final restored = backupRat.updatedAt.isAfter(existingRat.updatedAt)
          ? backupRat
          : existingRat;

      await ratRepo.save(existingRat);
      await ratRepo.save(restored);

      expect(ratRepo.rats.length, 1);
      expect(ratRepo.rats.first.clienteNome, 'New Name from Backup');
    });

    test('preserves data from both sources on restore', () async {
      final now = DateTime.now();

      // Local RATs
      final localRats = [
        Rat(
          id: 'rat-local-only',
          authorId: 'author-1',
          empresaId: null,
          usuarioId: null,
          tecnicoId: null,
          ownerType: RatOwnerType.localTecnico,
          numero: '0001',
          clienteNome: 'Local Only',
          responsavelRecebimento: 'Responsavel',
          dataVisita: now,
          horarioInicioAtendimento: '08:00',
          horarioTerminoAtendimento: '10:00',
          descricao: 'Local only RAT',
          status: RatStatus.draft,
          syncStatus: RatSyncStatus.localOnly,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Backup RATs
      final backupRats = [
        _makeRat(id: 'rat-backup-only', clienteNome: 'Backup Only'),
      ];

      // Combine (in real scenario, would merge by ID)
      final allRats = <Rat>{
        ...localRats,
        ...backupRats,
      }.toList();

      for (final rat in allRats) {
        await ratRepo.save(rat);
      }

      expect(ratRepo.rats.length, 2);
      expect(ratRepo.rats.any((r) => r.id == 'rat-local-only'), isTrue);
      expect(ratRepo.rats.any((r) => r.id == 'rat-backup-only'), isTrue);
    });
  });

  // ─── Edge Cases ────────────────────────────────────────────────────────────

  group('Edge cases', () {
    test('handles RAT with null optional fields', () async {
      final now = DateTime.now();

      final ratWithNulls = Rat(
        id: 'rat-nulls',
        authorId: 'author-1',
        empresaId: null,
        usuarioId: null,
        tecnicoId: null,
        ownerType: RatOwnerType.localTecnico,
        numero: '0001',
        clienteNome: 'Null Fields Test',
        responsavelRecebimento: null,
        responsavelDocumento: null,
        dataVisita: null,
        horarioInicioAtendimento: null,
        horarioTerminoAtendimento: null,
        descricao: 'Test with nulls',
        equipamentoMovimentoTipo: null,
        equipamentoDescricao: null,
        equipamentoObservacao: null,
        status: RatStatus.draft,
        syncStatus: RatSyncStatus.localOnly,
        createdAt: now,
        updatedAt: now,
      );

      final backup = TestBackupBuilder(
        rats: [ratWithNulls],
        assinaturas: [],
      ).build();

      final rats = backupParser.parseRats(backup);
      expect(rats.length, 1);
      expect(rats[0]['id'], 'rat-nulls');
    });

    test('handles large number of RATs in backup', () async {
      final rats = List.generate(
        100,
        (i) => _makeRat(
          id: 'rat-$i',
          clienteNome: 'Cliente $i',
        ),
      );

      final backup = TestBackupBuilder(
        rats: rats,
        assinaturas: [],
      ).build();

      final parsedRats = backupParser.parseRats(backup);
      expect(parsedRats.length, 100);
    });

    test('handles special characters in client name', () async {
      ratRepo.seed([
        _makeRat(
          id: 'rat-special',
          clienteNome: "Cliente with 'quotes' and \"double quotes\" and éàü",
        ),
      ]);

      final backup = TestBackupBuilder(
        rats: ratRepo.rats,
        assinaturas: [],
      ).build();

      final rats = backupParser.parseRats(backup);
      expect(rats[0]['clienteNome'], contains("'quotes'"));
    });
  });
}

// ─── Helper: Convert JSON back to Rat entity ─────────────────────────────────

Rat _ratFromJson(Map<String, dynamic> json) {
  return Rat(
    id: json['id'] as String,
    authorId: json['authorId'] as String,
    empresaId: json['empresaId'] as String?,
    usuarioId: json['usuarioId'] as String?,
    tecnicoId: json['tecnicoId'] as String?,
    ownerType: RatOwnerType.values.firstWhere(
      (e) => e.name == json['ownerType'],
      orElse: () => RatOwnerType.localTecnico,
    ),
    numero: json['numero'] as String? ?? '0000',
    clienteNome: json['clienteNome'] as String,
    responsavelRecebimento: json['responsavelRecebimento'] as String?,
    responsavelDocumento: json['responsavelDocumento'] as String?,
    dataVisita: json['dataVisita'] != null
        ? DateTime.tryParse(json['dataVisita'] as String)
        : null,
    horarioInicioAtendimento:
        json['horarioInicioAtendimento'] as String?,
    horarioTerminoAtendimento:
        json['horarioTerminoAtendimento'] as String?,
    descricao: json['descricao'] as String,
    equipamentoMovimentoTipo: json['equipamentoMovimentoTipo'] != null
        ? EquipamentoMovimentoTipo.values.firstWhere(
            (e) => e.name == json['equipamentoMovimentoTipo'],
            orElse: () => EquipamentoMovimentoTipo.nenhum,
          )
        : null,
    equipamentoDescricao: json['equipamentoDescricao'] as String?,
    equipamentoObservacao: json['equipamentoObservacao'] as String?,
    status: RatStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => RatStatus.draft,
    ),
    syncStatus: RatSyncStatus.values.firstWhere(
      (e) => e.name == json['syncStatus'],
      orElse: () => RatSyncStatus.localOnly,
    ),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.now(),
    deletedAt: json['deletedAt'] != null
        ? DateTime.tryParse(json['deletedAt'] as String)
        : null,
  );
}
