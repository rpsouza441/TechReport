import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/app/navigation/app_bootstrap_view_model.dart';
import 'package:techreport/features/company_auth/domain/entities/app_mode_preference.dart';
import 'package:techreport/features/company_auth/domain/entities/remote_endpoint_config.dart';
import 'package:techreport/features/company_auth/domain/repositories/app_mode_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/auth_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_endpoint_repository.dart';
import 'package:techreport/features/company_auth/domain/usecases/bootstrap_company_session.dart';
import 'package:techreport/features/company_auth/domain/usecases/select_app_mode.dart';
import 'package:techreport/features/local_auth/domain/repositories/pin_secret_repository.dart';
import 'package:techreport/features/local_auth/domain/repositories/sessao_local_repository.dart';
import 'package:techreport/features/local_auth/domain/repositories/tecnico_local_repository.dart';
import 'package:techreport/features/local_auth/domain/usecases/bootstrap_local_session.dart';
import 'package:techreport/features/local_auth/domain/usecases/change_local_pin.dart';
import 'package:techreport/features/local_auth/domain/usecases/complete_local_onboarding.dart';
import 'package:techreport/features/local_auth/domain/usecases/lock_local_session.dart';
import 'package:techreport/features/local_auth/domain/usecases/unlock_local_session.dart';
import 'package:techreport/features/local_auth/presentation/view_models/app_session_view_model.dart';

void main() {
  late _FakeAppModeRepository appModeRepository;
  late _FakeRemoteEndpointRepository endpointRepository;

  AppBootstrapViewModel buildViewModel() {
    final unused = _UnusedRepos();
    final localSessionViewModel = AppSessionViewModel(
      bootstrapLocalSession: BootstrapLocalSession(unused),
      changeLocalPin: ChangeLocalPin(
        pinSecretRepository: unused,
        sessaoLocalRepository: unused,
        tecnicoLocalRepository: unused,
      ),
      completeLocalOnboarding: CompleteLocalOnboarding(
        tecnicoLocalRepository: unused,
        sessaoLocalRepository: unused,
        pinSecretRepository: unused,
      ),
      lockLocalSession: LockLocalSession(unused),
      unlockLocalSession: UnlockLocalSession(
        unused,
        pinSecretRepository: unused,
      ),
    );

    return AppBootstrapViewModel(
      localSessionViewModel: localSessionViewModel,
      bootstrapCompanySession: BootstrapCompanySession(
        appModeRepository: appModeRepository,
        authRepository: unused,
      ),
      selectAppMode: SelectAppMode(appModeRepository),
      remoteEndpointRepository: endpointRepository,
    );
  }

  setUp(() {
    appModeRepository = _FakeAppModeRepository();
    endpointRepository = _FakeRemoteEndpointRepository();
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

  test(
    'requireRemoteEndpoint com isChangingServer marca a flag de troca',
    () {
      final viewModel = buildViewModel();

      viewModel.requireRemoteEndpoint(isChangingServer: true);

      expect(viewModel.status, AppBootstrapStatus.remoteEndpointRequired);
      expect(viewModel.isChangingServer, isTrue);
    },
  );

  test('requireModeChoice limpa preferencia e volta para escolha de modo',
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
  });
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
class _UnusedRepos
    implements
        SessaoLocalRepository,
        PinSecretRepository,
        TecnicoLocalRepository,
        AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
