import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/app/navigation/app_bootstrap_view_model.dart';
import 'package:techreport/features/company_auth/domain/entities/app_mode_preference.dart';
import 'package:techreport/features/company_auth/domain/entities/remote_endpoint_config.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/repositories/app_mode_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/auth_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_endpoint_repository.dart';
import 'package:techreport/features/company_auth/domain/usecases/bootstrap_company_session.dart';
import 'package:techreport/features/company_auth/domain/usecases/select_app_mode.dart';
import 'package:techreport/features/local_auth/domain/repositories/pin_secret_repository.dart';
import 'package:techreport/features/local_auth/domain/repositories/sessao_local_repository.dart';
import 'package:techreport/features/local_auth/domain/repositories/tecnico_local_repository.dart';
import 'package:techreport/features/local_auth/domain/entities/sessao_local.dart';
import 'package:techreport/features/local_auth/domain/usecases/bootstrap_local_session.dart';
import 'package:techreport/features/local_auth/domain/usecases/complete_local_onboarding.dart';
import 'package:techreport/features/local_auth/presentation/view_models/app_session_view_model.dart';

void main() {
  late _FakeAppModeRepository appModeRepository;
  late _FakeRemoteEndpointRepository endpointRepository;
  late _FakeAuthRepository authRepository;

  AppBootstrapViewModel buildViewModel({SessaoLocal? localSession}) {
    final localRepositories = _LocalRepositories(localSession);
    final localSessionViewModel = AppSessionViewModel(
      bootstrapLocalSession: BootstrapLocalSession(
        localRepositories,
        pinSecretRepository: localRepositories,
      ),
      completeLocalOnboarding: CompleteLocalOnboarding(
        tecnicoLocalRepository: localRepositories,
        sessaoLocalRepository: localRepositories,
      ),
    );

    return AppBootstrapViewModel(
      localSessionViewModel: localSessionViewModel,
      bootstrapCompanySession: BootstrapCompanySession(
        appModeRepository: appModeRepository,
        authRepository: authRepository,
      ),
      selectAppMode: SelectAppMode(appModeRepository),
      remoteEndpointRepository: endpointRepository,
    );
  }

  setUp(() {
    appModeRepository = _FakeAppModeRepository();
    endpointRepository = _FakeRemoteEndpointRepository();
    authRepository = _FakeAuthRepository();
  });

  test(
    'chooseCompany com endpoint salvo vai para remoteLoginRequired',
    () async {
      endpointRepository.activeEndpoint = _sampleEndpoint();
      final viewModel = buildViewModel();

      await viewModel.chooseCompany();

      expect(viewModel.status, AppBootstrapStatus.remoteLoginRequired);
      // Persistiu o modo empresa.
      expect(appModeRepository.savedPreference?.lastMode, AppMode.company);
    },
  );

  test(
    'chooseCompany sem endpoint salvo vai para remoteEndpointRequired',
    () async {
      endpointRepository.activeEndpoint = null;
      final viewModel = buildViewModel();

      await viewModel.chooseCompany();

      expect(viewModel.status, AppBootstrapStatus.remoteEndpointRequired);
      expect(viewModel.isChangingServer, isFalse);
    },
  );

  test('requireRemoteEndpoint com isChangingServer marca a flag de troca', () {
    final viewModel = buildViewModel();

    viewModel.requireRemoteEndpoint(isChangingServer: true);

    expect(viewModel.status, AppBootstrapStatus.remoteEndpointRequired);
    expect(viewModel.isChangingServer, isTrue);
  });

  test(
    'requireModeChoice limpa preferencia e volta para escolha de modo',
    () async {
      endpointRepository.activeEndpoint = _sampleEndpoint();
      final viewModel = buildViewModel();
      viewModel.requireRemoteEndpoint(isChangingServer: true);

      await viewModel.requireModeChoice();

      expect(viewModel.status, AppBootstrapStatus.modeChoiceRequired);
      expect(viewModel.isChangingServer, isFalse);
      expect(appModeRepository.cleared, isTrue);
      // requireModeChoice nao apaga o endpoint salvo.
      expect(endpointRepository.cleared, isFalse);
      expect(endpointRepository.activeEndpoint, isNotNull);
    },
  );

  test(
    'bootstrap local legado vai direto para home sem estado localLocked',
    () async {
      appModeRepository.savedPreference = AppModePreference(
        lastMode: AppMode.local,
        updatedAt: DateTime.utc(2026, 8, 9),
      );
      final viewModel = buildViewModel(localSession: _legacyLocalSession());
      final emitted = <String>[];
      viewModel.addListener(() => emitted.add(viewModel.status.name));

      await viewModel.bootstrap();

      expect(viewModel.status, AppBootstrapStatus.localUnlocked);
      expect(emitted, isNot(contains('localLocked')));
      expect(
        AppBootstrapStatus.values.map((status) => status.name),
        isNot(contains('localLocked')),
      );
    },
  );

  test('bootstrap empresa continua restaurando sessao valida', () async {
    appModeRepository.savedPreference = AppModePreference(
      lastMode: AppMode.company,
      updatedAt: DateTime.utc(2026, 8, 9),
    );
    authRepository.restoredSession = _remoteSession();
    final viewModel = buildViewModel();

    await viewModel.bootstrap();

    expect(viewModel.status, AppBootstrapStatus.companyUnlocked);
    expect(viewModel.remoteSession, same(authRepository.restoredSession));
  });
}

SessaoLocal _legacyLocalSession() {
  final now = DateTime.utc(2026, 8, 9, 12);
  return SessaoLocal(
    id: 'sessao-local-1',
    tecnicoLocalId: 'tecnico-local-1',
    status: SessaoLocalStatus.locked,
    pinConfigured: true,
    biometriaDisponivel: true,
    biometriaHabilitada: true,
    onboardingConcluido: true,
    createdAt: now,
    updatedAt: now,
  );
}

SessaoRemota _remoteSession() {
  final now = DateTime.now();
  return SessaoRemota(
    id: 'sessao-remota-1',
    empresaId: 'empresa-1',
    usuarioId: 'usuario-1',
    tecnicoId: 'tecnico-1',
    email: 'tecnico@example.com',
    nome: 'Tecnico',
    mustChangePassword: false,
    papelGlobal: null,
    papelEmpresa: SessaoRemotaPapelEmpresa.tecnico,
    accessTokenRef: 'access-ref',
    refreshTokenRef: 'refresh-ref',
    endpointRef: 'endpoint-1',
    expiresAt: now.add(const Duration(hours: 1)),
    lastValidatedAt: now,
    offlineAccessUntil: now.add(const Duration(days: 1)),
    createdAt: now,
    updatedAt: now,
  );
}

RemoteEndpointConfig _sampleEndpoint() {
  final now = DateTime(2026, 1, 1);
  return RemoteEndpointConfig(
    id: 'endpoint-1',
    nome: 'Servidor de teste',
    supabaseUrl: 'https://example.supabase.co',
    supabasePublicKeyRef: 'company_auth.endpoint-1.key',
    tipo: 'supabase',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAppModeRepository implements AppModeRepository {
  AppModePreference? savedPreference;
  bool cleared = false;

  @override
  Future<AppModePreference?> getPreference() async => savedPreference;

  @override
  Future<void> savePreference(AppModePreference preference) async {
    savedPreference = preference;
  }

  @override
  Future<void> clearPreference() async {
    cleared = true;
    savedPreference = null;
  }
}

class _FakeRemoteEndpointRepository implements RemoteEndpointRepository {
  RemoteEndpointConfig? activeEndpoint;
  bool cleared = false;

  @override
  Future<RemoteEndpointConfig?> getActiveEndpoint() async => activeEndpoint;

  @override
  Future<String?> readSupabasePublicKey(RemoteEndpointConfig endpoint) async =>
      'anon-key';

  @override
  Future<void> saveActiveEndpoint({
    required RemoteEndpointConfig endpoint,
    required String supabasePublicKey,
  }) async {
    activeEndpoint = endpoint;
  }

  @override
  Future<void> clearActiveEndpoint() async {
    cleared = true;
    activeEndpoint = null;
  }
}

/// Fake genérico para dependências que `chooseCompany`/`requireModeChoice`
/// não invocam. Qualquer chamada inesperada lança via `noSuchMethod`.
class _LocalRepositories
    implements
        SessaoLocalRepository,
        PinSecretRepository,
        TecnicoLocalRepository {
  _LocalRepositories(this.session);

  SessaoLocal? session;

  @override
  Future<SessaoLocal?> getCurrentSession() async => session;

  @override
  Future<void> saveSession(SessaoLocal value) async => session = value;

  @override
  Future<void> deletePin() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  SessaoRemota? restoredSession;

  @override
  Future<SessaoRemota?> restoreSession() async => restoredSession;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
