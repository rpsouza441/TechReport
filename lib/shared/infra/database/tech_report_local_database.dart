import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  TextColumn get ownerType => text()();
  TextColumn get numero => text()();
  TextColumn get clienteNome => text()();
  TextColumn get descricao => text()();
  TextColumn get status => text()();
  TextColumn get syncStatus => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [TecnicoLocals, SessaoLocals, Rats])
class TechReportLocalDatabase extends _$TechReportLocalDatabase {
  TechReportLocalDatabase()
    : super(
        driftDatabase(
          name: 'tech_report_local.sqlite',
          native: const DriftNativeOptions(),
        ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(rats);
      }
    },
  );
}
