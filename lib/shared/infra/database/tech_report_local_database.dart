// ATENCAO DEV: ao aplicar mudanca de criptografia em ambiente de
// desenvolvimento, limpar dados/cache do app antes de testar.
// Storage persistente do Android: app data / data / br.dev.rodrigopinheiro.techreport
// Em prod: migracao real necessaria antes de ativar criptografia.

import 'package:drift/drift.dart';

part 'tech_report_local_database.g.dart';

class TecnicoLocals extends Table {
  TextColumn get id => text()();
  TextColumn get nome => text()();
  TextColumn get email => text()();
  TextColumn get telefone => text().nullable()();
  TextColumn get empresaNome => text().nullable()();
  TextColumn get assinaturaPadraoRef => text().nullable()();
  BoolColumn get pinConfigured => boolean()();
  BoolColumn get biometriaHabilitada => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SessaoLocals extends Table {
  TextColumn get id => text()();
  TextColumn get mode => text()();
  TextColumn get tecnicoLocalId => text()();
  TextColumn get status => text()();
  BoolColumn get pinConfigured => boolean()();
  BoolColumn get biometriaDisponivel => boolean()();
  BoolColumn get biometriaHabilitada => boolean()();
  BoolColumn get onboardingConcluido => boolean()();
  DateTimeColumn get lastUnlockedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Rats extends Table {
  TextColumn get id => text()();
  TextColumn get authorId => text()();
  TextColumn get empresaId => text().nullable()();
  TextColumn get usuarioId => text().nullable()();
  TextColumn get tecnicoId => text().nullable()();
  TextColumn get ownerType => text()();
  TextColumn get numero => text()();
  TextColumn get clienteNome => text()();
  TextColumn get responsavelRecebimento => text().nullable()();
  TextColumn get responsavelDocumento => text().nullable()();
  DateTimeColumn get dataVisita => dateTime().nullable()();
  TextColumn get horarioInicioAtendimento => text().nullable()();
  TextColumn get horarioTerminoAtendimento => text().nullable()();
  TextColumn get descricao => text()();
  TextColumn get equipamentoMovimentoTipo => text().nullable()();
  TextColumn get equipamentoDescricao => text().nullable()();
  TextColumn get equipamentoObservacao => text().nullable()();
  TextColumn get status => text()();
  TextColumn get syncStatus => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Assinaturas extends Table {
  TextColumn get id => text()();
  TextColumn get ratId => text()();
  TextColumn get storageMode => text()();
  TextColumn get assetRef => text()();
  BlobColumn get dataBlob => blob().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get sha256 => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncQueueItems extends Table {
  TextColumn get id => text()();
  TextColumn get empresaId => text()();
  TextColumn get usuarioId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  TextColumn get status => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [TecnicoLocals, SessaoLocals, Rats, Assinaturas, SyncQueueItems],
)
class TechReportLocalDatabase extends _$TechReportLocalDatabase {
  /// Construtor principal - recebe QueryExecutor do openEncryptedDatabase().
  TechReportLocalDatabase(super.executor);

  /// Cria banco com criptografia via SQLite3MultipleCiphers.
  /// O [executor] deve ser aberto via openEncryptedDatabase() com PRAGMA key.
  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(rats);
      }
      if (from < 3) {
        await m.createTable(assinaturas);
      }
      if (from < 4) {
        await m.createTable(syncQueueItems);
      }
      if (from >= 2 && from < 5) {
        await _addRatColumnIfMissing(m, 'empresa_id', rats.empresaId);
        await _addRatColumnIfMissing(m, 'usuario_id', rats.usuarioId);
        await _addRatColumnIfMissing(m, 'tecnico_id', rats.tecnicoId);
      }
      if (from >= 2 && from < 6) {
        await _addRatColumnIfMissing(
          m,
          'responsavel_recebimento',
          rats.responsavelRecebimento,
        );
        await _addRatColumnIfMissing(m, 'data_visita', rats.dataVisita);
        await _addRatColumnIfMissing(
          m,
          'horario_inicio_atendimento',
          rats.horarioInicioAtendimento,
        );
        await _addRatColumnIfMissing(
          m,
          'horario_termino_atendimento',
          rats.horarioTerminoAtendimento,
        );
        await _addRatColumnIfMissing(
          m,
          'equipamento_movimento_tipo',
          rats.equipamentoMovimentoTipo,
        );
        await _addRatColumnIfMissing(
          m,
          'equipamento_descricao',
          rats.equipamentoDescricao,
        );
        await _addRatColumnIfMissing(
          m,
          'equipamento_observacao',
          rats.equipamentoObservacao,
        );
      }
      if (from >= 2 && from < 7) {
        await _addRatColumnIfMissing(
          m,
          'responsavel_documento',
          rats.responsavelDocumento,
        );
      }
      if (from < 8) {
        await _addAssinaturaColumnIfMissing(
          m,
          'data_blob',
          assinaturas.dataBlob,
        );
        await _addAssinaturaColumnIfMissing(
          m,
          'size_bytes',
          assinaturas.sizeBytes,
        );
        await _addAssinaturaColumnIfMissing(m, 'sha256', assinaturas.sha256);
        await _addAssinaturaColumnIfMissing(
          m,
          'mime_type',
          assinaturas.mimeType,
        );
      }
    },
  );

  Future<void> _addRatColumnIfMissing(
    Migrator migrator,
    String columnName,
    GeneratedColumn column,
  ) async {
    final exists = await _ratsHasColumn(columnName);
    if (exists) {
      return;
    }

    await migrator.addColumn(rats, column);
  }

  Future<bool> _ratsHasColumn(String columnName) async {
    final rows = await customSelect('PRAGMA table_info(rats)').get();
    return rows.any((row) => row.data['name'] == columnName);
  }

  Future<void> _addAssinaturaColumnIfMissing(
    Migrator migrator,
    String columnName,
    GeneratedColumn column,
  ) async {
    final exists = await _assinaturasHasColumn(columnName);
    if (exists) {
      return;
    }

    await migrator.addColumn(assinaturas, column);
  }

  Future<bool> _assinaturasHasColumn(String columnName) async {
    final rows = await customSelect('PRAGMA table_info(assinaturas)').get();
    return rows.any((row) => row.data['name'] == columnName);
  }
}
