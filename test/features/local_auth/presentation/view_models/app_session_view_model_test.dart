import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/local_auth/domain/entities/sessao_local.dart';
import 'package:techreport/features/local_auth/domain/entities/tecnico_local.dart';
import 'package:techreport/features/local_auth/domain/repositories/pin_secret_repository.dart';
import 'package:techreport/features/local_auth/domain/repositories/sessao_local_repository.dart';
import 'package:techreport/features/local_auth/domain/repositories/tecnico_local_repository.dart';
import 'package:techreport/features/local_auth/domain/usecases/bootstrap_local_session.dart';
import 'package:techreport/features/local_auth/domain/usecases/complete_local_onboarding.dart';
import 'package:techreport/features/local_auth/presentation/view_models/app_session_view_model.dart';

void main() {
  group('bootstrap local sem PIN', () {
    test(
      'perfil legado bloqueado fica pronto e remove somente o PIN',
      () async {
        final sessions = _FakeSessaoLocalRepository(
          current: _session(
            status: SessaoLocalStatus.locked,
            pinConfigured: true,
          ),
        );
        final pins = _RecordingPinSecretRepository(hasLegacyPin: true);
        final viewModel = _viewModel(sessions: sessions, pins: pins);

        await viewModel.bootstrap();

        expect(viewModel.status, AppSessionStatus.ready);
        expect(viewModel.isLoading, isFalse);
        expect(sessions.saved, hasLength(1));
        expect(sessions.saved.single.status, SessaoLocalStatus.unlocked);
        expect(sessions.saved.single.pinConfigured, isFalse);
        expect(pins.deleteCalls, 1);
        expect(pins.readOrWriteCalls, isEmpty);
      },
    );

    test('flag sem PIN ainda remove segredo legado residual', () async {
      final sessions = _FakeSessaoLocalRepository(
        current: _session(
          status: SessaoLocalStatus.unlocked,
          pinConfigured: false,
        ),
      );
      final pins = _RecordingPinSecretRepository(hasLegacyPin: true);
      final viewModel = _viewModel(sessions: sessions, pins: pins);

      await viewModel.bootstrap();

      expect(viewModel.status, AppSessionStatus.ready);
      expect(pins.deleteCalls, 1);
      expect(pins.readOrWriteCalls, isEmpty);
    });

    test(
      'falha ao abrir/carregar dados acontece antes de apagar o PIN',
      () async {
        final sessions = _FakeSessaoLocalRepository(
          loadError: StateError('Falha ao abrir os dados locais'),
        );
        final pins = _RecordingPinSecretRepository(hasLegacyPin: true);
        final viewModel = _viewModel(sessions: sessions, pins: pins);

        await expectLater(viewModel.bootstrap(), throwsA(isA<StateError>()));

        expect(pins.deleteCalls, 0);
        expect(pins.readOrWriteCalls, isEmpty);
      },
    );

    test('falha ao limpar PIN legado nao mascara sessao pronta', () async {
      final sessions = _FakeSessaoLocalRepository(
        current: _session(
          status: SessaoLocalStatus.locked,
          pinConfigured: true,
        ),
      );
      final pins = _RecordingPinSecretRepository(
        hasLegacyPin: true,
        deleteError: StateError('secure storage indisponivel'),
      );
      final viewModel = _viewModel(sessions: sessions, pins: pins);

      await viewModel.bootstrap();

      expect(viewModel.status, AppSessionStatus.ready);
      expect(pins.deleteCalls, 1);
      expect(pins.readOrWriteCalls, isEmpty);
    });
  });

  group('onboarding local somente com perfil', () {
    test('sem perfil permanece em onboardingRequired', () async {
      final viewModel = _viewModel(
        sessions: _FakeSessaoLocalRepository(),
        pins: _RecordingPinSecretRepository(),
      );

      await viewModel.bootstrap();

      expect(viewModel.status, AppSessionStatus.onboardingRequired);
    });

    test('nome e email bastam para criar sessao pronta', () async {
      final sessions = _FakeSessaoLocalRepository();
      final technicians = _FakeTecnicoLocalRepository();
      final pins = _RecordingPinSecretRepository();
      final viewModel = _viewModel(
        sessions: sessions,
        technicians: technicians,
        pins: pins,
      );

      await viewModel.submitOnboarding(
        nome: '  Ana Técnica  ',
        email: '  ana@example.com  ',
        telefone: ' 11999999999 ',
        empresaNome: ' Oficina Local ',
      );

      expect(viewModel.status, AppSessionStatus.ready);
      expect(viewModel.errorMessage, isNull);
      expect(technicians.saved.single.nome, 'Ana Técnica');
      expect(technicians.saved.single.email, 'ana@example.com');
      expect(sessions.saved.single.pinConfigured, isFalse);
      expect(sessions.saved.single.status, SessaoLocalStatus.unlocked);
      expect(pins.deleteCalls, 0);
      expect(pins.readOrWriteCalls, isEmpty);
    });

    test('validacao de perfil continua sem qualquer regra de PIN', () async {
      final viewModel = _viewModel(
        sessions: _FakeSessaoLocalRepository(),
        pins: _RecordingPinSecretRepository(),
      );

      await viewModel.submitOnboarding(nome: '', email: 'invalido');

      expect(viewModel.status, AppSessionStatus.onboardingRequired);
      expect(viewModel.errorMessage, 'Informe o nome do técnico.');
    });
  });
}

AppSessionViewModel _viewModel({
  required _FakeSessaoLocalRepository sessions,
  required _RecordingPinSecretRepository pins,
  _FakeTecnicoLocalRepository? technicians,
}) {
  final tecnicoRepository = technicians ?? _FakeTecnicoLocalRepository();
  return AppSessionViewModel(
    bootstrapLocalSession: BootstrapLocalSession(
      sessions,
      pinSecretRepository: pins,
    ),
    completeLocalOnboarding: CompleteLocalOnboarding(
      tecnicoLocalRepository: tecnicoRepository,
      sessaoLocalRepository: sessions,
    ),
  );
}

SessaoLocal _session({
  required SessaoLocalStatus status,
  required bool pinConfigured,
}) {
  final now = DateTime.utc(2026, 8, 9, 12);
  return SessaoLocal(
    id: 'sessao-local-1',
    tecnicoLocalId: 'tecnico-local-1',
    status: status,
    pinConfigured: pinConfigured,
    biometriaDisponivel: true,
    biometriaHabilitada: true,
    onboardingConcluido: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeSessaoLocalRepository implements SessaoLocalRepository {
  _FakeSessaoLocalRepository({this.current, this.loadError});

  SessaoLocal? current;
  final Object? loadError;
  final List<SessaoLocal> saved = [];

  @override
  Future<SessaoLocal?> getCurrentSession() async {
    final error = loadError;
    if (error != null) throw error;
    return current;
  }

  @override
  Future<void> saveSession(SessaoLocal session) async {
    saved.add(session);
    current = session;
  }

  @override
  Future<void> deleteSession() async => current = null;
}

class _FakeTecnicoLocalRepository implements TecnicoLocalRepository {
  final List<TecnicoLocal> saved = [];

  @override
  Future<TecnicoLocal?> getCurrent() async => saved.isEmpty ? null : saved.last;

  @override
  Future<void> save(TecnicoLocal tecnicoLocal) async {
    saved.add(tecnicoLocal);
  }
}

class _RecordingPinSecretRepository implements PinSecretRepository {
  _RecordingPinSecretRepository({this.hasLegacyPin = false, this.deleteError});

  bool hasLegacyPin;
  final Object? deleteError;
  int deleteCalls = 0;
  final List<String> readOrWriteCalls = [];

  @override
  Future<void> deletePin() async {
    deleteCalls += 1;
    final error = deleteError;
    if (error != null) throw error;
    hasLegacyPin = false;
  }

  @override
  Future<bool> hasPin() async {
    readOrWriteCalls.add('hasPin');
    return hasLegacyPin;
  }

  @override
  Future<void> savePin(String pin) async {
    readOrWriteCalls.add('savePin:$pin');
    hasLegacyPin = true;
  }

  @override
  Future<bool> verifyPin(String pin) async {
    readOrWriteCalls.add('verifyPin:$pin');
    return false;
  }
}
