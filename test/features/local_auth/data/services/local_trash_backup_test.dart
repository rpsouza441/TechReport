import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_parser.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_service.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_backup.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_data_import.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_backup.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'TechReport',
      packageName: 'com.techreport.test',
      version: '20.2.0',
      buildNumber: '1',
      buildSignature: 'test-signature',
    );
  });

  group('exportacao local com lixeira', () {
    test('serializa RAT ativa e excluida com contagens separadas', () async {
      final source = _FakeRatRepository([
        _rat(id: 'rat-active'),
        _rat(
          id: 'rat-trash',
          deletedAt: DateTime.parse('2026-08-09T14:30:00Z'),
        ),
      ]);
      final service = _service(source);

      final bytes = await service.exportBackup();
      final parser = LocalBackupParser();
      final manifest = parser.parseManifest(bytes);
      final rats = parser.parseRats(bytes);

      expect(source.listAllLocalForBackupCalls, 1);
      expect(source.listLocalCalls, 0);
      expect(manifest.schema, 'techreport.backup.v1');
      expect(manifest.counts.rats, 2);
      expect(manifest.counts.ratsActive, 1);
      expect(manifest.counts.ratsTrash, 1);
      expect(parser.validateIntegrity(bytes), isTrue);
      expect(rats.map((rat) => rat['id']), ['rat-active', 'rat-trash']);
      expect(rats.first['deletedAt'], isNull);
      expect(rats.last['deletedAt'], '2026-08-09T14:30:00.000Z');
    });

    test(
      'arquivo e manifest nao exportam chave caminho PIN ou token',
      () async {
        final bytes = await _service(
          _FakeRatRepository([_rat(id: 'rat-safe')]),
        ).exportBackup();
        final archiveText = _archiveText(bytes).toLowerCase();

        for (final forbidden in [
          'db_encryption_key',
          'local_pin',
          'secure_storage',
          'databasepath',
          'database_path',
          'access_token',
          'refresh_token',
          'super-secret-key-material',
        ]) {
          expect(archiveText, isNot(contains(forbidden)), reason: forbidden);
        }
      },
    );
  });

  group('preview e restore ativos+lixeira', () {
    test(
      'preview informa total, ativas e na lixeira antes de aplicar',
      () async {
        final bytes = await _service(
          _FakeRatRepository([
            _rat(id: 'rat-active'),
            _rat(id: 'rat-trash', deletedAt: DateTime.utc(2026, 8, 9)),
          ]),
        ).exportBackup();

        final preview = await PreviewLocalBackup(parser: LocalBackupParser())(
          bytes,
        );

        expect(preview.totalRats, 2);
        expect(preview.ratsActive, 1);
        expect(preview.ratsTrash, 1);
        expect(preview.checksumsValid, isTrue);
        expect(preview.canApply, isTrue);
      },
    );

    test(
      'apply restaura os dois estados de exclusao sem normalizar a lixeira',
      () async {
        final bytes = await _service(
          _FakeRatRepository([
            _rat(id: 'rat-active'),
            _rat(
              id: 'rat-trash',
              deletedAt: DateTime.parse('2026-08-09T14:30:00Z'),
            ),
          ]),
        ).exportBackup();
        final targetRats = _FakeRatRepository([]);
        final signatures = _FakeAssinaturaRepository();
        final apply = ApplyLocalBackup(
          parser: LocalBackupParser(),
          applyLocalDataImport: ApplyLocalDataImport(
            ratRepository: targetRats,
            assinaturaRepository: signatures,
          ),
        );

        final result = await apply(
          bytes: bytes,
          conflictPolicy: LocalImportConflictPolicy.overwrite,
        );

        expect(result.importedRats, 2);
        expect(targetRats.saved, hasLength(2));
        expect(
          targetRats.saved
              .singleWhere((rat) => rat.id == 'rat-active')
              .deletedAt,
          isNull,
        );
        expect(
          targetRats.saved
              .singleWhere((rat) => rat.id == 'rat-trash')
              .deletedAt,
          DateTime.parse('2026-08-09T14:30:00Z'),
        );
      },
    );
  });

  group('compatibilidade techreport.backup.v1', () {
    test(
      'manifest legado apenas com total continua aceito e deriva split',
      () async {
        final current = await _service(
          _FakeRatRepository([
            _rat(id: 'rat-active'),
            _rat(id: 'rat-trash', deletedAt: DateTime.utc(2026, 8, 9)),
          ]),
        ).exportBackup();
        final legacy = _rewriteManifest(current, (manifest) {
          final counts = manifest['counts']! as Map<String, dynamic>;
          counts.remove('ratsActive');
          counts.remove('ratsTrash');
        });
        final parser = LocalBackupParser();

        final manifest = parser.parseManifest(legacy);
        final preview = await PreviewLocalBackup(parser: parser)(legacy);

        expect(manifest.schema, 'techreport.backup.v1');
        expect(manifest.counts.rats, 2);
        expect(manifest.counts.ratsActive, isNull);
        expect(manifest.counts.ratsTrash, isNull);
        expect(parser.validateIntegrity(legacy), isTrue);
        expect(preview.ratsActive, 1);
        expect(preview.ratsTrash, 1);
        expect(preview.canApply, isTrue);
      },
    );

    test('split inconsistente e rejeitado sem ignorar checksums', () async {
      final current = await _service(
        _FakeRatRepository([_rat(id: 'rat-active')]),
      ).exportBackup();
      final inconsistent = _rewriteManifest(current, (manifest) {
        final counts = manifest['counts']! as Map<String, dynamic>;
        counts['ratsActive'] = 1;
        counts['ratsTrash'] = 1;
      });

      expect(
        () => LocalBackupParser().parseManifest(inconsistent),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

LocalBackupService _service(_FakeRatRepository rats) {
  return LocalBackupService(
    ratRepository: rats,
    assinaturaRepository: _FakeAssinaturaRepository(),
    localSignatureAssetStore: LocalSignatureAssetStore(),
  );
}

Rat _rat({required String id, DateTime? deletedAt}) {
  final createdAt = DateTime.parse('2026-08-01T10:00:00Z');
  return Rat(
    id: id,
    authorId: 'local-author',
    empresaId: null,
    usuarioId: null,
    tecnicoId: 'local-tecnico',
    ownerType: RatOwnerType.localTecnico,
    numero: id == 'rat-active' ? '0001' : '0002',
    clienteNome: 'Cliente $id',
    responsavelRecebimento: 'Responsavel',
    dataVisita: createdAt,
    horarioInicioAtendimento: '08:00',
    horarioTerminoAtendimento: '09:00',
    descricao: 'Atendimento local',
    status: RatStatus.finalizado,
    syncStatus: RatSyncStatus.localOnly,
    createdAt: createdAt,
    updatedAt: createdAt,
    deletedAt: deletedAt,
  );
}

String _archiveText(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  return archive
      .map((file) => utf8.decode(file.readBytes()!, allowMalformed: true))
      .join('\n');
}

Uint8List _rewriteManifest(
  Uint8List bytes,
  void Function(Map<String, dynamic> manifest) rewrite,
) {
  final decoded = ZipDecoder().decodeBytes(bytes);
  final output = Archive();
  for (final file in decoded) {
    var content = file.readBytes()!;
    if (file.name == 'manifest.json') {
      final manifest = jsonDecode(utf8.decode(content)) as Map<String, dynamic>;
      rewrite(manifest);
      content = utf8.encode(jsonEncode(manifest));
    }
    output.addFile(ArchiveFile.bytes(file.name, content));
  }
  return Uint8List.fromList(ZipEncoder().encode(output)!);
}

class _FakeRatRepository implements RatRepository {
  _FakeRatRepository(this.allLocal);

  final List<Rat> allLocal;
  final List<Rat> saved = [];
  int listLocalCalls = 0;
  int listAllLocalForBackupCalls = 0;

  @override
  Future<List<Rat>> listLocal() async {
    listLocalCalls += 1;
    return allLocal.where((rat) => rat.deletedAt == null).toList();
  }

  Future<List<Rat>> listAllLocalForBackup() async {
    listAllLocalForBackupCalls += 1;
    return List<Rat>.of(allLocal);
  }

  @override
  Future<Rat?> getById(String id) async {
    for (final rat in saved) {
      if (rat.id == id) return rat;
    }
    return null;
  }

  @override
  Future<void> save(Rat rat) async {
    saved.removeWhere((existing) => existing.id == rat.id);
    saved.add(rat);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAssinaturaRepository implements AssinaturaRepository {
  final List<Assinatura> saved = [];

  @override
  Future<List<Assinatura>> listByRatId(String ratId) async => const [];

  @override
  Future<Assinatura?> getById(String id) async => null;

  @override
  Future<void> save(Assinatura assinatura) async => saved.add(assinatura);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
