import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/app/theme/app_theme_mode.dart';
import 'package:techreport/app/theme/app_theme_repository.dart';
import 'package:techreport/app/theme/app_theme_variant.dart';
import 'package:techreport/app/theme/app_theme_view_model.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_parser.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_service.dart';
import 'package:techreport/features/local_auth/data/services/local_data_import_parser.dart';
import 'package:techreport/features/local_auth/domain/entities/sessao_local.dart';
import 'package:techreport/features/local_auth/domain/entities/tecnico_local.dart';
import 'package:techreport/features/local_auth/domain/repositories/pin_secret_repository.dart';
import 'package:techreport/features/local_auth/domain/repositories/sessao_local_repository.dart';
import 'package:techreport/features/local_auth/domain/repositories/tecnico_local_repository.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_data_import.dart';
import 'package:techreport/features/local_auth/domain/usecases/bootstrap_local_session.dart';
import 'package:techreport/features/local_auth/domain/usecases/complete_local_onboarding.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_data_import.dart';
import 'package:techreport/features/local_auth/presentation/screens/local_settings_screen.dart';
import 'package:techreport/features/local_auth/presentation/view_models/app_session_view_model.dart';
import 'package:techreport/features/local_auth/presentation/widgets/local_info_card.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renderiza agrupamento prescritivo e sete capacidades offline', (
    tester,
  ) async {
    await _pumpAdministration(tester);

    expect(find.text('Administração local'), findsOneWidget);
    expect(
      find.text(
        'Gerencie somente os dados deste dispositivo. '
        'Nada aqui depende do servidor.',
      ),
      findsOneWidget,
    );
    for (final section in [
      'Perfil e conteúdo',
      'Aparência',
      'Backup e dados',
      'Modo de operação',
    ]) {
      expect(find.text(section), findsOneWidget, reason: section);
    }
    for (final capability in [
      'Meu perfil',
      'RATs',
      'Lixeira',
      'Tema do app',
      'Exportar backup',
      'Restaurar backup',
      'Informações dos dados',
    ]) {
      expect(find.text(capability), findsOneWidget, reason: capability);
    }
    expect(find.text('Trocar para modo empresa'), findsOneWidget);
  });

  testWidgets('remove PIN biometria bloqueio e qualquer segredo da UI', (
    tester,
  ) async {
    await _pumpAdministration(tester);

    final forbidden = find.textContaining(
      RegExp(
        r'PIN|biometr|bloquear|desbloque|db_encryption_key|local_pin|'
        r'secure.storage|[/\\]data[/\\]|super-secret',
        caseSensitive: false,
      ),
    );
    expect(forbidden, findsNothing);
    expect(find.byIcon(Icons.pin_outlined), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.byIcon(Icons.fingerprint), findsNothing);
  });

  testWidgets('informacoes exibem somente contagens e criptografia segura', (
    tester,
  ) async {
    await _pumpAdministration(tester);
    await tester.scrollUntilVisible(
      find.text('Informações dos dados'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Informações dos dados'));
    await tester.pumpAndSettle();

    expect(find.text('RATs ativas'), findsOneWidget);
    expect(find.text('Na lixeira'), findsOneWidget);
    expect(find.text('Última atualização local'), findsOneWidget);
    expect(
      find.text(
        'O banco local continua criptografado. '
        'A chave é gerenciada automaticamente pelo app.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        RegExp(
          r'db_encryption_key|local_pin|super-secret|[/\\]data[/\\]',
          caseSensitive: false,
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('acoes respeitam alvo minimo de 48dp', (tester) async {
    await _pumpAdministration(tester);

    final cards = find.byType(LocalInfoCard);
    expect(cards, findsNWidgets(8));
    for (var index = 0; index < cards.evaluate().length; index++) {
      final size = tester.getSize(cards.at(index));
      expect(size.height, greaterThanOrEqualTo(48), reason: 'card $index');
      expect(size.width, greaterThanOrEqualTo(48), reason: 'card $index');
    }
  });

  testWidgets('escala de texto 200% mantem secoes e acoes sem overflow', (
    tester,
  ) async {
    await _pumpAdministration(tester, textScale: 2);

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Trocar para modo empresa'), findsOneWidget);
  });
}

Future<void> _pumpAdministration(
  WidgetTester tester, {
  double textScale = 1,
}) async {
  final repository = _LocalRatRepository([
    _rat(id: 'rat-active'),
    _rat(id: 'rat-trash', deletedAt: DateTime.utc(2026, 8, 9)),
  ]);
  final themeViewModel = AppThemeViewModel(
    repository: _MemoryThemeRepository(),
  );
  await themeViewModel.load();

  await tester.pumpWidget(
    MaterialApp(
      theme: themeViewModel.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: LocalAdministrationScreen(
          appSessionViewModel: _sessionViewModel(),
          themeViewModel: themeViewModel,
          onSwitchMode: () async {},
          ratRepository: repository,
          localBackupService: _UnusedLocalBackupService(),
          localBackupParser: LocalBackupParser(),
          localDataImportParser: LocalDataImportParser(),
          applyLocalDataImport: _UnusedApplyLocalDataImport(),
          previewLocalDataImport: _UnusedPreviewLocalDataImport(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppSessionViewModel _sessionViewModel() {
  final repositories = _LocalSessionRepositories();
  return AppSessionViewModel(
    bootstrapLocalSession: BootstrapLocalSession(
      repositories,
      pinSecretRepository: repositories,
    ),
    completeLocalOnboarding: CompleteLocalOnboarding(
      tecnicoLocalRepository: repositories,
      sessaoLocalRepository: repositories,
    ),
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

class _LocalSessionRepositories
    implements
        SessaoLocalRepository,
        TecnicoLocalRepository,
        PinSecretRepository {
  @override
  Future<SessaoLocal?> getCurrentSession() async => null;

  @override
  Future<void> deletePin() async {}

  @override
  Future<void> saveSession(SessaoLocal session) async {}

  @override
  Future<void> save(TecnicoLocal tecnicoLocal) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryThemeRepository extends AppThemeRepository {
  AppThemeVariant variant = AppThemeVariant.cobalt;
  AppThemeModePreference mode = AppThemeModePreference.system;

  @override
  Future<AppThemeVariant> loadVariant() async => variant;

  @override
  Future<AppThemeModePreference> loadMode() async => mode;

  @override
  Future<void> saveVariant(AppThemeVariant value) async => variant = value;

  @override
  Future<void> saveMode(AppThemeModePreference value) async => mode = value;
}

class _LocalRatRepository implements RatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  _LocalRatRepository(this.rats);

  final List<Rat> rats;

  @override
  Future<List<Rat>> listLocal() async =>
      rats.where((rat) => rat.deletedAt == null).toList();

  Future<List<Rat>> listAllLocalForBackup() async => List<Rat>.of(rats);

  Future<List<Rat>> listDeletedLocalCursor({
    required int limit,
    DateTime? lastDeletedAt,
    String? lastId,
  }) async => rats.where((rat) => rat.deletedAt != null).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedLocalBackupService implements LocalBackupService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedApplyLocalDataImport implements ApplyLocalDataImport {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedPreviewLocalDataImport implements PreviewLocalDataImport {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
